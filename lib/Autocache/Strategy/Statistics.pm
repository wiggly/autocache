package Autocache::Strategy::Statistics;

use Any::Moose;

extends 'Autocache::Strategy';

use Autocache;
###l4p use Log::Log4perl qw( get_logger );

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
# hashref containing our stats
#
has 'statistics' => (
    is => 'rw',
    isa => 'HashRef',
    lazy_build => 1,
);

sub create
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
###l4p     get_logger()->debug( "create" );
    ++$self->statistics->{create};
    return $self->base_strategy->create(
        $name,$normaliser,$coderef,$args,$return_type);
}

sub get
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
###l4p     get_logger()->debug( "get" );
    my $rec = $self->base_strategy->get(
        $name, $normaliser, $coderef, $args, $return_type );
    if( $rec )
    {
        ++$self->statistics->{hit};
    }
    else
    {
        ++$self->statistics->{miss};
    }
    ++$self->statistics->{total};
    return $rec;
}

sub set
{
    my ($self,$rec) = @_;
###l4p     get_logger()->debug( "set " . $rec->name );
    return $self->base_strategy->set( $rec );
}

sub _build_base_strategy
{
    return Autocache->singleton->get_default_strategy();
}

sub _build_statistics
{
    return {
        hit => 0,
        miss => 0,
        create => 0,
        total => 0,
    };
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
