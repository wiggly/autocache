package Autocache;

use version; $VERSION = qv('0.1');

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Log::Log4perl qw( get_logger );

use Autocache::Config;
use Autocache::Store::UnboundedMemory;
use Autocache::Strategy::Simple;
use Autocache::WorkQueue;

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT = ();
our @EXPORT_OK = qw( autocache );

my $SINGLETON;

sub autocache
{
    my ($name,$args) = @_;
    get_logger()->debug( "autocache $name" );
    my $package = caller;
    __PACKAGE__->singleton->_cache_function( $package, $name, $args );
}

sub singleton
{
    my $class = shift;
    __PACKAGE__->initialise()
        unless $SINGLETON;
    return $SINGLETON;
}

sub initialise
{
    my $class = shift;
    $SINGLETON = $class->new( @_ );
    $SINGLETON->configure;
}

sub new
{
    my ($class,%args) = @_;
    my $config = Autocache::Config->new( $args{filename} );
    my $self =
        {
            config => $config,
            store => {},
            strategy => {},
            default_strategy => undef,
            work_queue => undef,
        };
    bless $self, $class;
    return $self;
}

sub configure
{
    my ($self) = @_;
    
    foreach my $node ( $self->{config}->get_node( 'store' )->children )
    {
        my $name = $node->name;
        my $package = $node->value;
        _use_package( $package );

        my $store;

        eval
        {
            $store = $package->new( $node );
        };
        if( $@ )
        {
            confess "cannot create store $name using package $package - $@";
        }
        $self->{store}{$node->name} = $store;
    }

    foreach my $node ( $self->{config}->get_node( 'strategy' )->children )
    {
        my $name = $node->name;
        my $package = $node->value;
        _use_package( $package );

        my $strategy;

        eval
        {
            $strategy = $package->new( $node );
        };
        if( $@ )
        {
            confess "cannot create strategy $name using package $package - $@";
        }
        $self->{strategy}{$node->name} = $strategy;
    }

    $self->configure_functions( $self->{config}->get_node( 'fn' ) );

#    if( $self->{config}->get_node( 'default_store' ) )
#    {
#        $self->{default_store} = $self->get_store(
#            $self->{config}->get_node( 'default_store' )->value );
#    }

    if( $self->{config}->node_exists( 'default_strategy' ) )
    {
        $self->{default_strategy} = $self->get_strategy(
            $self->{config}->get_node( 'default_strategy' )->value );
    }

    my $stats = $self->{config}->get_node( 'stats' );
    if( $stats->node_exists( 'enable' ) )
    {
        $self->{enable_stats} = $stats->get_node( 'enable' )->value;
    }
    
    if( exists $ENV{AUTOCACHE_STATS} )
    {
        $self->{enable_stats} = $ENV{AUTOCACHE_STATS};
    }
    
    if( $stats->node_exists( 'dump_on_exit' ) )
    {
        $self->{dump_stats} = $stats->get_node( 'dump_on_exit' )->value;
    }
}

sub configure_functions
{
    my ($self,$node,$namespace) = @_;
    
    $namespace ||= '';

    if( $node->value )
    {
        get_logger()->debug( "fn: $namespace -> " . $node->value );

        $self->{fn}{$namespace}{strategy} = $node->value;
    }

    foreach my $child ( $node->children )
    {
        $self->configure_functions( $child, $namespace . '::' . $child->name );
    }
}

sub cache_function
{
    my ($self,$name,$args) = @_;
    get_logger()->debug( "cache_function '$name'" );
    my $package = caller;
    $self->_cache_function( $package, $name, $args );
}

sub _cache_function
{
    my ($self,$package,$name,$args) = @_;

    get_logger()->debug( "_cache_function '$name'" );

    # r : cache routine name
    my $r = '::' . $package . '::' . $name;

    # n : cache routine normaliser name
    my $n = '::' . $package . '::_normalise_' . $name;

    # g : generator routine name
    my $g = __PACKAGE__ . '::G' . $r;

    get_logger()->debug( "cache : $r / $g"  );

    no strict 'refs';
    
    # get generator routine ref
    my $gsub = *{$r}{CODE};

    # see if we have a normaliser
    my $gsub_norm = *{$n}{CODE};
    
    unless( defined $gsub_norm )
    {
        get_logger()->debug( "no normaliser, using default" );
        $gsub_norm = $self->get_default_normaliser();
    }

    my $rsub = $self->_generate_cached_fn( $r, $gsub_norm, $gsub );

    {
        # avoid "subroutine redefined" warning
        no warnings;
        # setup cached routine for caller
        *{$r} = $rsub;
    }
    1;
}

sub run_work_queue
{
    my($self) = @_;
    get_logger()->debug( "run_work_queue" );
    $self->get_work_queue()->execute();
}

sub get_work_queue
{
    my ($self) = @_;
    get_logger()->debug( "get_work_queue" );
    unless( $self->{work_queue} )
    {
        $self->{work_queue} = Autocache::WorkQueue->new();
    }
    return $self->{work_queue};
}

sub get_strategy_for_fn
{
    my ($self,$name) = @_;
    get_logger()->debug( "get_strategy_for_fn '$name'" );
    
    return $self->get_default_strategy()
        unless exists $self->{fn}{$name}{strategy};

    return $self->get_strategy( $self->{fn}{$name}{strategy} );
}

sub get_strategy
{
    my ($self,$name) = @_;
    get_logger()->debug( "get_strategy '$name'" );
    confess "cannot find strategy $name"
        unless $self->{strategy}{$name};
    return $self->{strategy}{$name};
}

sub get_store
{
    my ($self,$name) = @_;
    get_logger()->debug( "get_store '$name'" );
    confess "cannot find store $name"
        unless $self->{store}{$name};
    return $self->{store}{$name};
}

sub get_default_strategy
{
    my ($self) = @_;
    get_logger()->debug( "get_default_strategy" );
    unless( $self->{default_strategy} )
    {
        $self->{default_strategy} = Autocache::Strategy::Simple->new(
            store => $self->get_default_store() );
    }
    return $self->{default_strategy};
}

sub get_default_store
{
    my ($self) = @_;
    get_logger()->debug( "get_default_store" );
    unless( $self->{default_store} )
    {
        $self->{default_store} = Autocache::Store::UnboundedMemory->new;
    }
    return $self->{default_store};
}

sub get_default_normaliser
{
    my ($self) = @_;
    get_logger()->debug( "get_default_normaliser" );
    return \&_default_normaliser;
}

sub _generate_cached_fn
{
    my ($self,$name,$normaliser,$coderef) = @_;
    get_logger()->debug( "_generate_cached_fn $name" );

    return sub
    {
        get_logger()->debug( "CACHE $name" );
        return unless defined wantarray;
        my $return_type = wantarray ? 'L' : 'S';

        get_logger()->debug( "return type: $return_type" );

        my $strategy = $self->get_strategy_for_fn( $name );
        my $value = $strategy->get_cache_record(
            $name, $normaliser, $coderef, \@_, $return_type )->value;

        return wantarray ? @$value : $value;
    };
}

sub _default_normaliser
{
    get_logger()->debug( "_default_normaliser" );
    return join ':', @_;
}

sub _use_package
{
    my ($name) = @_;
    get_logger()->debug( "use $name" );    
    eval "use $name";
    if( $@ )
    {
        confess $@;
    }
}

sub _dump_stats
{
    my ($self) = @_;
    print STDERR "AUTOCACHE STATS\n";
    foreach my $name ( keys %{$self->{strategy}} )
    {
        print STDERR "STRATEGY: $name\n";

        my $strategy = $self->{strategy}{$name};

#        print STDERR "STRAT: ", Dumper( $strategy ), "\n";

        next unless $strategy;
    
        my $stats = $strategy->get_statistics();

        if( $stats->{total} > 0 )
        {
            printf STDERR "hit  : %8d / %3.2f%%\n",
                $stats->{hit},
                ( $stats->{hit} / $stats->{total} ) * 100;
            printf STDERR "miss : %8d / %3.2f%%\n",
                $stats->{miss},
                ( $stats->{miss} / $stats->{total} ) * 100;
            printf STDERR "total: %d\n", $stats->{total};
        }
        else
        {
            print STDERR "no statistics available\n";
        }
        print STDERR "\n";
    }

    foreach my $strategy ( values %{$self->{strategy}} )
    {
#        print STDERR "STRAT: ", Dumper( $strategy ), "\n";

        next unless $strategy;
    
        my $stats = $strategy->get_statistics();

        if( $stats->{total} > 0 )
        {
#            printf STDERR "hit  : %-8d / %-3.2f\n",
#                ( $stats->{hit} / $stats->{total} ) * 100;
#            printf STDERR "miss : %-8d / %-3.2f\n",
#                ( $stats->{miss} / $stats->{total} ) * 100;
#            printf STDERR "total: %d\n", $stats->{total};
        }
        else
        {
#            print STDERR "no statistics available\n";
        }
#        print STDERR "\n";
    }

    print STDERR "AUTOCACHE STATS DONE\n";
}

1;
