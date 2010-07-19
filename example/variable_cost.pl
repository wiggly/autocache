#!/usr/bin/env perl

use strict;
use warnings;
use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init( $DEBUG );

use lib '../lib';

use Autocache qw( autocache );

Autocache->initialise( filename => './variable_cost.conf' );

autocache 'square';

foreach my $n ( 1..10 )
{
    get_logger()->debug( "n: $n" );
    foreach my $i ( 1..10 )
    {
        get_logger()->debug( "i: $i" );
        my $val = square( $n * 100 );
    }
}

exit;

#
# square function that takes time proportional to the value being squared
#
sub square
{
    my ($millis) = @_;
    my $sec = $millis / 1000;    

    get_logger()->info( "sleep $sec" );

    select undef, undef, undef, $sec;
    return $millis * $millis;
}
