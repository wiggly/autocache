package Autocache::Store;

use Any::Moose;

use Log::Log4perl qw( get_logger );

#
# get KEY
#
sub get {}

#
# set KEY RECORD
#
sub set {}

#
# delete KEY
#
sub delete {}

#
# clear
#
sub clear {}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
