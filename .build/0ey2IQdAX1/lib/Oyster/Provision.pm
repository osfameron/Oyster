package Oyster::Provision;

use Moose;

has 'name'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'size'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'image'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'pub_ssh' => ( is => 'ro', isa => 'Str', required => 1 );

has 'config'  => (is => 'rw', isa => 'HashRef', required => 1 );

sub BUILD {

    my $self = shift;

    if(!exists($self->config()->{provision_backend})) {
        $self->config()->{provision_backend} = 'Oyster::Provision::Rackspace';
    }
    
    my $role = $self->config()->{provision_backend};

    eval "use $role";
    "$role"->meta->apply($self);
}

1;

__END__

=head1 NAME

Oyster::Provision - Provision an Oyster

=head1 SYNOPSIS

    my $server = Oyster::Provision->new(
        name => 'Ostrica',
        size => '256',
        image => 'Meerkat',
        pub_ssh => "$ENV{HOME}/.ssh/id_rsa.pub",
    );
    $server->create;

=head1 BACKENDS

By default, the L<Oyster::Provision::Rackspace> backend
will be used.

Each backend needs to accept at least the C<name>,
C<size>, C<image> and C<pub_ssh> parameters. The meaning
of these parameters may differ from one backend to another.

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
