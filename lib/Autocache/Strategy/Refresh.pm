package Autocache::Strategy::Refresh;

use Any::Moose;

extends 'Autocache::Strategy';

#use Carp;
use Carp qw( cluck );
use Autocache;
use Log::Log4perl qw( get_logger );
#use Functions::Log qw( get_logger );
use Scalar::Util qw( weaken );

#
# Refresh Strategy - freshen content regularly in the background
#

#
# refresh_age : content older than this in seconds will be refreshed in the
# background by a work queue
#
has 'refresh_age' => (
    is => 'ro',
    isa => 'Int',
    default => 60,
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

#
# work_queue : object that provides a work_queue interface to push refresh
# jobs on to [default: Cacher::get_work_queue ]
#
has 'work_queue' => (
    is => 'ro',
    isa => 'Autocache::WorkQueue',
    lazy_build => 1,
);

sub get_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
    get_logger()->debug( "get_cache_record" );
#    my $key = $self->_generate_cache_key( $name, $normaliser, $args, $return_type );
    my $rec = $self->base_strategy->get_cache_record(
        $name, $normaliser, $coderef, $args, $return_type );    

    
    get_logger()->debug( "record age  : " . $rec->age );
    get_logger()->debug( "refresh age : " . $self->refresh_age );

    #
    # TODO - add min refresh time to stop cache stampede for shared caches
    #
    if( $rec and ( $rec->age > $self->refresh_age ) )
    {
        $self->work_queue->push(
            $self->_refresh_task(
                $name, $normaliser, $coderef, $args, $return_type, $rec ) );
    }

    unless( $rec )
    {
        $self->_miss;
        $rec = $self->_create_cache_record(
            $name, $normaliser, $coderef, $args, $return_type );
        $self->set_cache_record( $rec->key, $rec );
    }
    else
    {
        $self->_hit;
    }
    
    return $rec;    
}

sub set_cache_record
{
    my ($self,$rec) = @_;
    get_logger()->debug( "set_cache_record " . $rec->name );
    return $self->base_strategy->set_cache_record( $rec );    
}


sub _refresh_task
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type,$rec) = @_;

    get_logger()->debug( "_refresh_task " . $name );

    #
    # TODO - add code to update cache entry to stop cache-stampeding if the
    # underlying store is distributed/shared
    #

    weaken $self;
        
    return sub
    {
        get_logger()->debug( "refreshing record: " . $rec->to_string );
        my $fresh_rec = $self->_create_cache_record(
            $name, $normaliser, $coderef, $args, $return_type );
        $self->set_cache_record( $fresh_rec );
    };
}

sub _build_base_strategy
{
    return Autocache->singleton->get_default_strategy();
}

sub _build_work_queue
{
    return Autocache->singleton->get_work_queue();
}

#sub BUILD
#{
#    my ($self) = @_;    
#    use Data::Dumper;
#    print STDERR __PACKAGE__ . "::BUILD\n";
#    print STDERR "store: " . Dumper( \@_ ) . "\n";
#    cluck "building\n";
#}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $base_strategy_name = $config->get_node( 'base_strategy' )->value;

        get_logger()->debug( "base strategy : $base_strategy_name" );        

        $args{base_strategy} = Autocache->singleton->get_strategy( $base_strategy_name );

        $args{refresh_age} = 2;

#        print STDERR __PACKAGE__ . "::BUILDARGS\n";
#        print STDERR Dumper( \%args );
#        cluck "building args\n";

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
