#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 3;
use Log::Log4perl;
Log::Log4perl::init( 't/log.conf' );
use Autocache qw( autocache );

ok( autocache 'contextual', 'Autocache function' );

is( scalar( contextual() ), 'c', 'Scalar context' );

is_deeply( [ contextual() ], [ qw( a b ) ], 'List context' );

exit;

sub contextual
{
    my ($n) = @_;    
    return wantarray ? qw( a b ) : 'c';
}
