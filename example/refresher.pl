#!/usr/bin/env perl

use strict;
use warnings;
use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init( $INFO );

use lib '../lib';

use Autocache qw( autocache );

Autocache->initialise( filename => './refresher.conf' );

autocache 'cached_time';

my $finish = time + 30;

do
{
    printf "finish time: %d - cached time: %d\n",
        $finish,
        cached_time();
    Autocache->singleton->run_work_queue;
    sleep 1;
}
while( $finish > cached_time() );

exit;

sub cached_time
{
    time;
}
