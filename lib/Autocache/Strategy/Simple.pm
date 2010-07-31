package Autocache::Strategy::Simple;

use Any::Moose;

extends 'Autocache::Strategy';

use Carp qw( cluck );
###l4p use Log::Log4perl qw( get_logger );

has 'store' => (
    is => 'ro',
    isa => 'Autocache::Store',
    lazy_build => 1,
);

sub get
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
###l4p     get_logger()->debug( "get $name" );
    my $key = $self->_generate_cache_key(
        $name, $normaliser, $args, $return_type );
    my $rec = $self->store->get( $key );
    return $rec;
}

sub set
{
    my ($self,$rec) = @_;
###l4p     get_logger()->debug( "set " . $rec->name );
    return $self->store->set( $rec->key, $rec );
}

sub _build_store
{
    return Autocache->singleton->get_default_store();
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

        if( $config->node_exists( 'store' ) )
        {
            $node = $config->get_node( 'store' );
###l4p             get_logger()->debug( "found store node in config '" . $node->value . "'" );
            $args{store} = Autocache->singleton->get_store( $node->value );
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
