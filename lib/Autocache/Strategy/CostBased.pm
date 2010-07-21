package Autocache::Strategy::CostBased;

use Any::Moose;

extends 'Autocache::Strategy';

use Autocache;
use Time::HiRes qw( gettimeofday tv_interval );

use Log::Log4perl qw( get_logger );

#
# Cost-Based Strategy - only cache content that takes over a certain amount
# of time to generate
#

#
# cost_threshold : miniumum time that a function result must take to
# generate before it is considered for caching. (milliseconds)
#
has 'cost_threshold' => (
    is => 'ro',
    isa => 'Int',
    default => 1000,
);

#
# base_strategy : underlying strategy that handles storage and expiry -
# defaults
#
has 'base_strategy' => (
    is => 'ro',
    isa => 'Autocache::Strategy',
    lazy_build => 1,
);

sub create_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
    get_logger()->debug( "create_cache_record" );

    my $t0 = [gettimeofday];

    my $rec = $self->base_strategy->create_cache_record(
        $name,$normaliser,$coderef,$args,$return_type);

    my $elapsed = tv_interval ( $t0 );

    $rec->{time_cost} = $elapsed * 1_000;
    
    get_logger()->debug( "record time_cost  : " . $rec->time_cost );
    get_logger()->debug( "cost threshold : " . $self->cost_threshold );

    return $rec;
}

sub get_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
    get_logger()->debug( "get_cache_record" );

    my $rec = $self->base_strategy->get_cache_record(
        $name, $normaliser, $coderef, $args, $return_type );

    return $rec;
}

sub set_cache_record
{
    my ($self,$rec) = @_;
    get_logger()->debug( "set_cache_record " . $rec->name );
    # only put in cache if it has exceeded our cost threshold
    if( $rec->time_cost > $self->cost_threshold )
    {
        get_logger()->debug( "cost threshold exceeded setting in cache" );
        return $self->base_strategy->set_cache_record( $rec );
    }
}

sub _build_base_strategy
{
    return Autocache->singleton->get_default_strategy();
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $node;

        if( $node = $config->get_node( 'base_strategy' ) )
        {
            get_logger()->debug( "base strategy node found" );
            $args{base_strategy} = Autocache->singleton->get_strategy( $node->value );
        }
        
        if( $node = $config->get_node( 'cost_threshold' ) )
        {
            get_logger()->debug( "cost threshold node found" );
            my $millis = $node->value;
            
            unless( $millis =~ /^\d+$/ )
            {
                if( $millis =~ /(\d+)ms/ )
                {
                    $millis = $1;
                }
                elsif( $millis =~ /(\d+)s/ )
                {
                    $millis = $1 * 1000;
                }
                elsif( $millis =~ /(\d+)m/ )
                {
                    $millis = $1 * 1000 * 60;
                }
            }

            $args{cost_threshold} = $millis;

            get_logger()->debug( sprintf 'cost threshold : %dms', $millis );
        }

        return $class->$orig( %args );
    }
    else
    {
        return $class->$orig(@_);
    }
};


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
