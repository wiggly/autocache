#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 2;
use Log::Log4perl;
Log::Log4perl::init( 't/log.conf' );
use Autocache qw( autocache );

Autocache->initialise( filename => 't/004_stat.t.conf' );

ok( autocache 'fib', 'Autocache function' );

my $junk = fib( 65 );

is( fib( 65 ), 17167680177565, '65th Fibonacci number' );

my $strategy = Autocache->singleton->get_strategy( 'stats' );

my $stats = $strategy->statistics;

diag( 'stats' );
diag( sprintf 'create : %d %.2f%%',
    $stats->{create},
    ( $stats->{create} / $stats->{total} ) * 100 );

diag( sprintf 'hit    : %d %.2f%%',
    $stats->{hit},
    ( $stats->{hit} / $stats->{total} ) * 100 );

diag( sprintf 'miss   : %d %.2f%%',
    $stats->{miss},
    ( $stats->{miss} / $stats->{total} ) * 100 );

exit;

sub fib
{
    my ($n) = @_;    
    return 1 if( $n == 1 || $n == 2 );
    return ( fib( $n - 1 ) + fib( $n - 2 ) );
}
