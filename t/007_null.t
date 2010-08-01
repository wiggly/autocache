#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

###l4p use Log::Log4perl qw( :easy );
###l4p use Log::Log4perl::Resurrector;

use Autocache::Record;
use Autocache::Strategy::Null;

###l4p Log::Log4perl->easy_init( $DEBUG );

my $key = 'k';

my $rec = Autocache::Record->new( key => $key, value => 'data' );

my $st = Autocache::Strategy::Null->new;

$st->set( $key, $rec );

is( $st->get( $key ), undef, 'record not stored' );

exit;
