package Autocache::Store::Memcached;

use Any::Moose;

extends 'Autocache::Store';

use Cache::Memcached;
use Log::Log4perl qw( get_logger );
#use Functions::Log qw( get_logger );

#
# Null Memcached Strategy - never expire, memcached
#

has '_memcached' => (
    is => 'ro',
    init_arg => 'memcached', );

#
# get KEY
#
sub get
{
    my ($self,$key) = @_;
    get_logger()->debug( "get: $key" );
    return $self->_memcached->get( $key );
}

#
# set KEY RECORD
#
sub set
{
    my ($self,$key,$rec) = @_;
    $self->SUPER::set( $key, $rec );
    get_logger()->debug( "set: $key" );
    $self->_memcached->set( $key, $rec, 0 ); 
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete" );
    $self->_memcached->delete( $key );
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $servers = $config->get_node( 'servers' )->value || '127.0.0.1';
        my @servers = split /\s+/, $servers;
        $args{servers} = \@servers;

        if( $config->get_node( 'compress_threshold' ) )
        {
            $args{compress_threshold} = $config->get_node( 'compress_threshold' )->value;
        }

        return $class->$orig( memcached => Cache::Memcached->new( %args ) );
    }
    else
    {
        return $class->$orig(@_);
    }
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
