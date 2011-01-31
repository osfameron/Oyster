package Oyster::Provision::API;
use Moose::Role;
use namespace::autoclean;

requires qw(
  create
  delete
  resize
);

has config => (
    isa      => 'Oyster::Provision::Config',
    is       => 'ro',
    required => 1,
    handles  => [qw( name size image pub_ssh )],
);

has api_username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has api_password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
__END__
