package Oyster::Provision::Config;
use Moose;
use namespace::autoclean;

has [qw( name size image pub_ssh )] => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

1
__END__