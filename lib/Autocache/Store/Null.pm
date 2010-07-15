package Autocache::Store::Null;
use Any::Moose;
extends 'Autocache::Store';
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    return $class->$orig();
};
no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
