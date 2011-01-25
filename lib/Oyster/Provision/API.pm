package Oyster::Provision::API;
use Moose::Role;
use namespace::autoclean;

requires qw(
  create
  delete
  resize
  _build_api_username
  _build_api_password
);

has config => (
    isa      => 'Oyster::Provision::Config',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has api_username => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_api_username',
);

sub _build_api_username {
    return $ENV{CLOUDSERVERS_USER} if exists $ENV{CLOUDSERVERS_USER};
    die "Need api_username or CLOUDSERVERS_USER in environment";
}

has api_password => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_api_password',
);

sub _build_api_password {
    return $ENV{CLOUDSERVERS_KEY} if exists $ENV{CLOUDSERVERS_KEY};
    die "Need api_password or CLOUDSERVERS_KEY in environment";
}

1;
__END__
