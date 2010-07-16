#!/usr/bin/perl 

use strict;
use warnings;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init( $INFO );

use Test::More tests => 2;

use Autocache qw( autocache );

Autocache->initialise( filename => 't/003_refresh.t.conf' );

ok( autocache 'cached_time', 'Autocache function' );

ok( test_refresh(), 'Test refresh' );

exit;

sub test_refresh
{
    my $ok = 1;

    my $finish = time + 10;

    my $cached;
    my $current;

    do
    {
        $current = time();
        $cached = cached_time();

        if( ( $current - $cached ) > 3 )
        {
#            diag( "current: $current - cached: $cached - NOT OK" );
            $ok = 0;
        }

#        diag( "finish: $finish - cached: $cached" );

        Autocache->singleton->run_work_queue;
        sleep 1;    
    }
    while( $finish > $cached );

    return $ok;    
}

sub cached_time
{
    return time;
}
