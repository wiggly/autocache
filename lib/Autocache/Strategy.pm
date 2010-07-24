package Autocache::Strategy;

use Any::Moose;

use Autocache::Record;
use Log::Log4perl qw( get_logger );

sub get_cache_record { return undef; }

sub set_cache_record { return undef; }

#
# create a cache record by invoking the function to be cached
#
# this generates a basic cache record, strategies built on top of this
# should feel free to add their own data elements to the cache record
#
sub create_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
    get_logger()->debug( "create_cache_record" );
    my $value;

    if( $return_type eq 'S' )
    {
        $value = $coderef->( @$args );
    }
    else
    {
        my @value = $coderef->( @$args );
        $value = \@value;
    }
    
    my $key = $self->_generate_cache_key( $name, $normaliser, $args, $return_type );
    my $rec = Autocache::Record->new(
        name => $name,
        key => $key,
        value => $value,
    );
    return $rec;    
}

#
# take the name of a function, a normaliser and arguments, return the cache
# key to use for this combination
#
sub _generate_cache_key
{
    my ($self,$name,$normaliser,$args,$return_type) = @_;
    get_logger()->debug( "_generate_cache_key" );
    return sprintf 'AC-%s-%s-%s',
        $return_type, $name, $normaliser->( @$args );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
