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
sub set
{
    my ($self,$key,$rec) = @_;
    get_logger()->debug( "set: $key" );
    unless( $rec->cached )
    {
        $rec->{cached} = 1;
    }
    return 1;
}

#
# delete KEY
#
sub delete {}

#
# clear
#
sub clear {}

#
# statistics
#
sub statistics {}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
