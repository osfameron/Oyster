package Oyster::Provision;
use Moose;
use namespace::autoclean;

use Oyster::Provision::Config;

has config => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
);

has provision_class => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Oyster::Provision::Backend::Rackspace'
);

has 'provision_backend' => (
    does    => 'Oyster::Provision::API',
    handles => 'Oyster::Provision::API',
    lazy    => 1,
    builder => '_build_provision_backend',
);

sub _build_provision_backend {
    my $self  = shift;
    my $class = $self->provision_class;
    Class::MOP::load_class($class);

    my $config = $self->config;

    my $user = ( $config->{api_username} || $ENV{CLOUDSERVERS_USER} )
      or die 'Need api_username in the config or CLOUDSERVERS_USER in the environment';
    my $pass = ( $config->{api_password} || $ENV{CLOUDSERVERS_KEY} )
      or die 'Need api_password in the config or CLOUDSERVERS_KEY in the environment';

    $class->new(
        config       => Oyster::Provision::Config->new($self->config),
        api_username => $user,
        api_password => $pass,
    );
}
1;

__END__

=head1 NAME

Oyster::Provision - Provision an Oyster

=head1 SYNOPSIS

    my $server = Oyster::Provision->new(
        config => {
            name    => 'Ostrica',
            size    => '1',     # 256 MiB RAM
            image   => '69',    # Ubuntu 10.10 Maverick
            pub_ssh => "$ENV{HOME}/.ssh/id_rsa.pub",
        }
    );
    $server->create;

=head1 BACKENDS

By default, the L<Oyster::Provision::Rackspace> backend
will be used.

Each backend needs to accept at least the C<name>, C<size>, C<image> and
C<pub_ssh> configuration parameters. The meaning of these parameters may
differ from one backend to another.

=head1 METHOS

Each backend usually implements the following C<required>
methods:

=over

=item create

Creates a new server by given name, if such server does
not exist.

Installs the required packages for the distribution

=item delete

Gets rid of the server instance

=item resize

Hopefully scales the server

=back

=cut
