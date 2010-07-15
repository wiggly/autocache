package Autocache::Strategy::Refresh;

use Any::Moose;

extends 'Autocache::Strategy';

use Carp;
use Autocache;
use Log::Log4perl qw( get_logger );
#use Functions::Log qw( get_logger );
use Scalar::Util qw( weaken );

#
# Refresh Strategy - freshen content regularly in the background
#

#
# refresh_age : content older than this will be refreshed in the background
# by a work queue
#
has '_refresh_age' =>
( is => 'ro', default => 5, init_arg => 'refresh_age', );

#
# base_strategy : underlying strategy that handles storage and expiry -
# defaults
#
has '_base_strategy' => (
    is => 'ro',
    isa => 'Autocache::Strategy',
    lazy => 1,
    init_arg => 'base_strategy',
    builder => '_build__base_strategy',
);

#
# work_queue : object that provides a work_queue interface to push refresh
# jobs on to [default: Cacher::get_work_queue ]
#
has '_work_queue' => (
    is => 'ro',
    isa => 'Autocache::WorkQueue',
    lazy => 1,
    init_arg => 'work_queue', 
    builder => '_build__work_queue',
);

sub get_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
    get_logger()->debug( "get_cache_record" );
    my $key = $self->_generate_cache_key( $name, $normaliser, $args, $return_type );
    my $rec = $self->_base_strategy->get_cache_record(
        $name, $normaliser, $coderef, $args, $return_type );    

    #
    # TODO - add min refresh time to stop cache stampede for shared caches
    #
    if( $rec and ( $rec->age > $self->_refresh_age ) )
    {
        $self->_work_queue->push(
            $self->_refresh_task(
                $name, $normaliser, $coderef, $args, $return_type, $rec ) );
    }

    unless( $rec )
    {
        $self->_miss;
        $rec = $self->_create_cache_record(
            $name, $normaliser, $coderef, $args );
        $self->_base_strategy->set( $key, $rec );
    }
    else
    {
        $self->_hit;
    }
    
    return $rec;    
}

sub _refresh_task
{
    my ($self,$name,$normaliser,$coderef,$args,$rec) = @_;

    get_logger()->debug( "_refresh_task " . $rec->key );

    #
    # TODO - add code to update cache entry to stop cache-stampeding if the
    # underlying store is distributed/shared
    #

    weaken $self;
        
    return sub
    {
        get_logger()->debug( "refreshing record: " . $rec->to_string );
        my $fresh_rec = $self->_create_cache_record(
            $name, $normaliser, $coderef, $args );
        $self->_base_strategy->set( $rec->key, $fresh_rec );
    };
}

sub _build__base_strategy
{
    return Autocache->singleton->get_default_strategy();
}

sub _build__work_queue
{
    return Autocache->singleton->get_work_queue();
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
