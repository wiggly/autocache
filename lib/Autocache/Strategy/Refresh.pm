package Autocache::Strategy::Refresh;

use Any::Moose;

extends 'Autocache::Strategy';

use Autocache;
use Carp;
###l4p use Log::Log4perl qw( get_logger );
use Scalar::Util qw( weaken );

#
# Refresh Strategy - freshen content regularly in the background
#

#
# refresh_age : content older than this in seconds will be refreshed in the
# background by a work queue
#
has 'refresh_age' => (
    is => 'rw',
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
# jobs on to
#
has 'work_queue' => (
    is => 'ro',
    isa => 'Autocache::WorkQueue',
    lazy_build => 1,
);

sub create_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
###l4p     get_logger()->debug( "create_cache_record" );
    return $self->base_strategy->create_cache_record(
        $name,$normaliser,$coderef,$args,$return_type);
}

sub get_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
###l4p     get_logger()->debug( "get_cache_record" );
    my $rec = $self->base_strategy->get_cache_record(
        $name, $normaliser, $coderef, $args, $return_type );    
    

    #
    # TODO - add min refresh time to stop cache stampede for shared caches
    #
    if( $rec and ( $rec->age > $self->refresh_age ) )
    {
###l4p         get_logger()->debug( "record age  : " . $rec->age );
###l4p         get_logger()->debug( "refresh age : " . $self->refresh_age );

        $self->work_queue->push(
            $self->_refresh_task(
                $name, $normaliser, $coderef, $args, $return_type, $rec ) );
    }

    return $rec;    
}

sub set_cache_record
{
    my ($self,$rec) = @_;
###l4p     get_logger()->debug( "set_cache_record " . $rec->name );
    return $self->base_strategy->set_cache_record( $rec );    
}

sub _refresh_task
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type,$rec) = @_;

###l4p     get_logger()->debug( "_refresh_task " . $name );

    weaken $self;
        
    return sub
    {
###l4p         get_logger()->debug( "refreshing record: " . $rec->to_string );
        my $fresh_rec = $self->create_cache_record(
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

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

###l4p     get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $node;

        if( $node = $config->get_node( 'base_strategy' ) )
        {
###l4p             get_logger()->debug( "base strategy node found" );
            $args{base_strategy} = Autocache->singleton->get_strategy( $node->value );
        }
        
        if( $node = $config->get_node( 'refresh_age' ) )
        {
###l4p             get_logger()->debug( "refresh age node found" );
            $args{refresh_age} = $node->value;
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
