package Autocache::Store::UnboundedMemory;

use Any::Moose;

extends 'Autocache::Store';

use Log::Log4perl qw( get_logger );
#use Functions::Log qw( get_logger );
use Data::Dumper;

#
# Null Memory Strategy - never expire, in memory cache
#

has '_cache' => (
    is => 'rw',
    default => sub { {} },
    init_arg => undef,    
);

has '_stats' => (
    is => 'rw',
    default => sub { {} },
    init_arg => undef,
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
# statistics
#
sub statistics
{
    my ($self) = @_;
    return $self->_stats;
}

#
# dump FILEHANDLE
#
sub dump
{
    my ($self,$fh) = @_;
    print $fh "null memory stratgey dump\n";
    print $fh "-" x 76, "\n";
    print $fh Dumper( $self->_cache );
    print $fh "-" x 76, "\n";
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    return $class->$orig();
};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
