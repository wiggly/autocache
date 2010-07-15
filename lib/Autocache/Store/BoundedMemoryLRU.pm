package Autocache::Store::BoundedMemoryLRU;

use Any::Moose;

extends 'Autocache::Store';

use Log::Log4perl qw( get_logger );
#use Functions::Log qw( get_logger );
use Data::Dumper;

#
# Bounded LRU cache - not yet implemented as an LRU cache...need to go find
# one to plug in
#

has '_cache' => (
    is => 'rw',
    default => sub { {} },
    init_arg => undef,    
);

has 'size' => (
    is => 'ro',
    default => 1000,
);

#
# get KEY
#
sub get
{
    my ($self,$key) = @_;
    get_logger()->debug( "get: $key" );
    return unless exists $self->_cache->{$key};    
    return $self->_cache->{$key};
}

#
# set KEY RECORD
#
sub set
{
    my ($self,$key,$rec) = @_;
    get_logger()->debug( "set: $key" );
    $self->_cache->{$key} = $rec;    
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete: $key" );
    delete $self->_cache->{$key};
}

#
# clear
#
sub clear
{
    my ($self,$key) = @_;
    get_logger()->debug( "clear" );
    $self->_cache = {};
}

#
# dump FILEHANDLE
#
sub dump
{
    my ($self,$fh) = @_;
    print $fh "-" x 76, "\n";
    print $fh Dumper( $self->_cache );
    print $fh "-" x 76, "\n";
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        if( $config->get_node( 'size' ) )
        {
            $args{size} = $config->get_node( 'size' )->value;
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
