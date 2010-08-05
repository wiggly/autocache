use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Autocache',
    license => 'perl',
    dist_author => [ 'Nigel A Rantor <wiggly@wiggly.org>', 'Rajit B Singh <rajit.b.singh@gmail.com>' ],
    dist_version_from => 'lib/Autocache.pm',
    requires => {
	'perl' => '5.8.8',
        'Any::Moose' => 0,
        'Test::More' => 0,
        'Time::HiRes' => 0,
    },
    auto_features => {
        log4perl => {
            description => 'Log4perl',
            requires => {
                'Log::Log4perl' => '1.12',
            },
	},
	memory_lru => {
	    description => 'Memory LRU store',
	    requires => {
	        'Devel::Size' => '0.69',
	        'Heap' => '0.80',
            },
	},
    },
    PL_files => {
        't/006_lru.t.PL' => 't/006_lru.t',
    },
);

$builder->create_build_script();
