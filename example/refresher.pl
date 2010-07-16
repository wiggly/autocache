#!/usr/bin/perl -I /www/gumtree/cgi-bin

use strict;
use warnings;
use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init( $INFO );

use lib '../lib';

use Autocache qw( autocache );

Autocache->initialise( filename => './refresher.conf' );

autocache 'cached_time';

# If you're trying this with the above line commented out then you'll be
# waiting for...some time...

while( 1 )
{
    printf "cached time: %d\n", cached_time();
    Autocache->singleton->run_work_queue;
    sleep 1;
}

exit;

sub cached_time
{
    time;
}
