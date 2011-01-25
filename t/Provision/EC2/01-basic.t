use strict;
use Test::More;

use Oyster::Provision;

unless ( $ENV{TEST_AWS_USER} && $ENV{TEST_AWS_KEY} ) {
    plan skip_all => << 'END';
Set TEST_AWS_USER and TEST_AWS_KEY in your environment for this test to run'
END
}

ok(
    my $server = Oyster::Provision->new(
        provision_class => 'Oyster::Provision::EC2',
        config          => {
            api_username => $ENV{TEST_AWS_USER},
            api_password => $ENV{TEST_AWS_PASS},
        }
    )
);

done_testing();
