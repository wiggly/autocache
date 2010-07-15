#!/usr/bin/perl -I /www/gumtree/cgi-bin

use strict;
use warnings;
use Autocache qw( autocache );

Autocache->initialise( filename => './fib.conf' );

autocache 'fib';

# If you're trying this with the above line commented out then you'll be
# waiting for...some time...

foreach my $i ( 1..100 )
{
    print "fib $i : " . fib( $i ) . "\n";
}

exit;

sub fib
{
    my ($n) = @_;    
    return 1 if( $n == 1 || $n == 2 );
    return ( fib( $n - 1 ) + fib( $n - 2 ) );
}
