#!/usr/local/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Exception;

use File::Temp qw/tempdir/;

BEGIN { use_ok( 'Oyster::Deploy::Git' ); }

my $tmpdir = tempdir();

my $deploy = new_ok 'Oyster::Deploy::Git';

#create
is($deploy->create("${tmpdir}/testapp"), 1, 'Create returned okay');

ok((-d "${tmpdir}/testapp"), "App directory created");

throws_ok(sub {$deploy->create("${tmpdir}/testapp")}, 'Error::Simple', "Directory already exists");
