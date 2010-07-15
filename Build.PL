use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Autocache',
    license => 'perl',
    dist_author => 'Nigel Rantor <wiggly@wiggly.org>',
    dist_version_from => 'lib/Autocache.pm',
    requires => {
        'Any::Moose' => 0,
        'Test::More' => 0,
    },
);

$builder->create_build_script();
