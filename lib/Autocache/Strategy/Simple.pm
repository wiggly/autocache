package Autocache::Strategy::Simple;

use Any::Moose;

extends 'Autocache::Strategy';

use Log::Log4perl qw( get_logger );
#use Functions::Log qw( get_logger );
use Data::Dumper;
use Carp qw( cluck );

has 'store' => (
    is => 'ro',
    isa => 'Autocache::Store', );

sub get_cache_record
{
    my ($self,$name,$normaliser,$coderef,$args,$return_type) = @_;
    get_logger()->debug( "get_cache_record $name" );

#    print STDERR "get cache record\n";
#    print STDERR Dumper( $self );

    my $key = $self->_generate_cache_key( $name, $normaliser, $args, $return_type );

#    get_logger()->debug( "key $key" );

#    print STDERR "store ", Dumper( $self->store );


    my $rec = $self->store->get( $key );
    unless( $rec )
    {
        $self->_miss;
        $rec = $self->_create_cache_record( $name, $normaliser, $coderef, $args, $return_type );
        $self->store->set( $key, $rec );
    }
    else
    {
        $self->_hit;
    }
    
    return $rec;
}

sub set_cache_record
{
    my ($self,$rec) = @_;
    get_logger()->debug( "set_cache_record $rec->name" );
    return $self->store->set( $rec->key, $rec );    
}

#sub BUILD
#{
#    my ($self) = @_;
#    
#    print STDERR __PACKAGE__ . "::BUILD\n";
#    print STDERR "store: " . Dumper( $self->store ) . "\n";
#    cluck "building\n";
#}

around BUILDARGS => sub
{
    my $orig = shift;
    my $class = shift;

    get_logger()->debug( __PACKAGE__ . " - BUILDARGS" );

    if( ref $_[0] )
    {
        my $config = $_[0];
        my %args;
        my $store_name = $config->get_node( 'store' )->value;

        get_logger()->debug( "store name : $store_name" );        

        $args{store} = Autocache->singleton->get_store( $store_name );

#        print STDERR __PACKAGE__ . "::BUILDARGS\n";
#        print STDERR Dumper( \%args );
#        cluck "building args\n";

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
