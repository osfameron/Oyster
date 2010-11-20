package Oyster::Provision;

use Moose;

sub config {
    return {provision_backend => 'Oyster::Provision::Rackspace'};
}

sub BUILD {

    my $self = shift;

    my $role = $self->config()->{provision_backend};

    eval "use $role";
    "$role"->meta->apply($self);
}

1;
