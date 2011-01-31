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
        provision_class => 'Oyster::Provision::Backend::AmazonEC2',
        config          => {
            api_username => $ENV{TEST_AWS_USER},
            api_password => $ENV{TEST_AWS_KEY},
            size         => 'm1.small',
            name         => 'Oyster-Test',
            image        => 'ami-be6e99d7',
            pub_ssh      => "$ENV{HOME}/Dropbox/Public/id_rsa.pub",
        }
    ),
    'created server instance'
);

ok( $server->create, 'deployed server' );

ok( $server->delete, 'destroyed server' );

done_testing();
