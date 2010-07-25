package Autocache::Store::MemoryLRU;

use Any::Moose;

extends 'Autocache::Store';

use Autocache::Store::MemoryLRU::Entry;
use Devel::Size qw( total_size );
use Heap::Binary;
use Heap::Elem::Ref qw( RefElem );
use Log::Log4perl qw( get_logger );

has 'size' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'max_size' => (
    is => 'ro',
    isa => 'Int',
    default => 1024,
);

has '_heap' => (
    is => 'rw',
    lazy_build => 1,
);

has '_cache' => (
    is => 'rw',
    lazy_build => 1,
);

#
# get KEY
#
sub get
{
    my ($self,$key) = @_;
    get_logger()->debug( "get: $key" );
    return unless exists $self->_cache->{$key};
    my $elem = $self->_cache->{$key};
    $self->_heap->delete( $elem );
    $elem->val->touch;
    $self->_heap->add( $elem );
    return $elem->val->val;
}

#
# set KEY RECORD
#
sub set
{
    my ($self,$key,$rec) = @_;
    get_logger()->debug( "set: $key" );
    my $elem = RefElem( Autocache::Store::MemoryLRU::Entry->new(
        key => $key,
        val => $rec,
        size => total_size( $rec ) ) );

    my $size = $self->size + $elem->val->size;

    while( $size > $self->max_size )
    {
        get_logger()->debug( "cache size: $size" );

        my $lru = $self->_heap->extract_top;

        get_logger()->debug( "LRU key: " . $lru->val->key );

        $size -= $lru->val->size;
        delete $self->_cache->{$lru->val->key};
    }

    $self->size( $size );
    $self->_heap->add( $elem );
    $self->_cache->{$key} = $elem;
    return $elem->val->val;
}

#
# delete KEY
#
sub delete
{
    my ($self,$key) = @_;
    get_logger()->debug( "delete: $key" );
    my $elem = delete $self->_cache->{$key};
    $self->_heap->delete( $elem );
    $self->size( $self->size - $elem->val->size );
    return $elem->val->val;
}

#
# clear
#
sub clear
{
    my ($self,$key) = @_;
    get_logger()->debug( "clear" );
    $self->_cache = {};
    $self->_heap = Heap::Binary->new;
    $self->size( 0 );
}

sub _build__heap
{
    return Heap::Binary->new;
}

sub _build__cache
{
    return {};
}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $node;

        if( $node = $config->get_node( 'max_size' ) )
        {
            get_logger()->debug( "max_size node found" );
            $args{max_size} = $node->value;
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
