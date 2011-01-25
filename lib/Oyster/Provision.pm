package Oyster::Provision;
use Moose;
use namespace::autoclean;

has config => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
);

has provision_class => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Oyster::Provision::Rackspace'
);

has 'provision_backend' => (
    does    => 'Oyster::Provision::API',
    handles => 'Oyster::Provision::API',
    lazy    => 1,
    builder => '_build_provision_backend',
);

sub _build_provision_backend {
    my $self = shift;
    $self->provision_class->new( ${ $self->config } );
}
1;

__END__

=head1 NAME

Oyster::Provision - Provision an Oyster

=head1 SYNOPSIS

    my $server = Oyster::Provision->new(
        config => {
            name    => 'Ostrica',
            size    => '256',
            image   => 'Meerkat',
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
