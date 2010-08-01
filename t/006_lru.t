#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

###l4p use Log::Log4perl qw( :easy );
###l4p use Log::Log4perl::Resurrector;

use Autocache::Record;
use Autocache::Strategy::Eviction::LRU;
use Autocache::Strategy::Store::Memory;

###l4p Log::Log4perl->easy_init( $DEBUG );

use Devel::Size qw( total_size );

my %records;

foreach my $key ( 'a'..'e' )
{
    $records{$key} = Autocache::Record->new( key => $key, value => $key );
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

$store->set( $key, $records{$key} );

isnt( $store->get( 'a' ), undef, 'record not evicted' );

$key = 'b';

$store->set( $key, $records{$key} );

isnt( $store->get( 'a' ), undef, 'record not evicted' );
isnt( $store->get( 'b' ), undef, 'record not evicted' );

$key = 'c';

$store->set( $key, $records{$key} );

isnt( $store->get( 'a' ), undef, 'record not evicted' );
isnt( $store->get( 'b' ), undef, 'record not evicted' );
isnt( $store->get( 'c' ), undef, 'record not evicted' );

$key = 'd';

$store->set( $key, $records{$key} );

is( $store->get( 'a' ), undef, 'record has been evicted' );
isnt( $store->get( 'b' ), undef, 'record not evicted' );
isnt( $store->get( 'c' ), undef, 'record not evicted' );
isnt( $store->get( 'd' ), undef, 'record not evicted' );

exit;
