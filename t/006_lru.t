#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

###l4p use Log::Log4perl qw( :easy );
###l4p use Log::Log4perl::Resurrector;

use Autocache::Request;
use Autocache::Record;
use Autocache::Strategy::Eviction::LRU;
use Autocache::Strategy::Store::Memory;

###l4p Log::Log4perl->easy_init( $DEBUG );

use Devel::Size qw( total_size );

my %requests;
my %records;

foreach my $key ( 'a'..'e' )
{
    my $req = Autocache::Request->new(
        name => 'name',
        normaliser => sub { $_[0] },
        generator => sub { 'data' },
        args => [ $key ],
        context => 'S',
    );
    $requests{$key} = $req;
    $records{$key} = Autocache::Record->new( key => $req->key, value => 'data' );
}

my $record_size = total_size( $records{a} );

###l4p get_logger()->debug( "record size : $record_size" );

my $max_size = $record_size * 3;

###l4p get_logger()->debug( "max size : $max_size" );

my $store = Autocache::Strategy::Eviction::LRU->new(
    max_size => $max_size,
    base_strategy => Autocache::Strategy::Store::Memory->new, );

my $key;

$key = 'a';

$store->set( $requests{$key}, $records{$key} );

isnt( $store->get( $requests{a} ), undef, 'record not evicted' );

$key = 'b';

$store->set( $requests{$key}, $records{$key} );

isnt( $store->get( $requests{a} ), undef, 'record not evicted' );
isnt( $store->get( $requests{b} ), undef, 'record not evicted' );

$key = 'c';

$store->set( $requests{$key}, $records{$key} );

isnt( $store->get( $requests{a} ), undef, 'record not evicted' );
isnt( $store->get( $requests{b} ), undef, 'record not evicted' );
isnt( $store->get( $requests{c} ), undef, 'record not evicted' );

$key = 'd';

$store->set( $requests{$key}, $records{$key} );

is( $store->get( $requests{a} ), undef, 'record has been evicted' );
isnt( $store->get( $requests{b} ), undef, 'record not evicted' );
isnt( $store->get( $requests{c} ), undef, 'record not evicted' );
isnt( $store->get( $requests{d} ), undef, 'record not evicted' );

exit;
