package Oyster::Provision::Rackspace;
use Moose::Role;

requires 'config';

sub create {
   my $self = shift;

   $self->config();
}

sub delete {
   my $self = shift;

   $self->config();
}

sub resize {
   my $self = shift;

   $self->config();
}

1;

__END__

=head1 NAME

Oyster::Provision::Rackspace -- Provision your Oyster on Rackspace

=head1 SYNOPSIS

Use the Rackspace backend on your Oyster configuration file

=head1 REQUIRED PARAMETERS

The following are required to instantiate a backend:

=over

=item name

The name of your new/existing rackspace server.

=item size

The size ID of the rackspace server you want to create.
Use the following incantation to see them:

    perl -MNet::RackSpace::CloudServers -e'
        $r=Net::RackSpace::CloudServers->new(
            user=>$ENV{CLOUDSERVERS_USER},
            key=>$ENV{CLOUDSERVERS_KEY},
        );
        print map
            { "id $_->{id} ram $_->{ram} disk $_->{disk}\n" }
            $r->get_flavor_detail
    '
    id 1 ram 256 disk 10
    id 2 ram 512 disk 20
    id 3 ram 1024 disk 40
    id 4 ram 2048 disk 80
    id 5 ram 4096 disk 160
    id 6 ram 8192 disk 320
    id 7 ram 15872 disk 620

=item image

The image ID of the rackspace server you want to create.
Use the following incantation to see them:

    perl -MNet::RackSpace::CloudServers -e'
        $r=Net::RackSpace::CloudServers->new(
            user=>$ENV{CLOUDSERVERS_USER},
            key=>$ENV{CLOUDSERVERS_KEY},
        );
        print map
            { "id $_->{id} name $_->{name}\n" }
            $r->get_image_detail
    '
    id 29 name Windows Server 2003 R2 SP2 x86
    id 69 name Ubuntu 10.10 (maverick)
    id 41 name Oracle EL JeOS Release 5 Update 3
    id 40 name Oracle EL Server Release 5 Update 4
    id 187811 name CentOS 5.4
    id 4 name Debian 5.0 (lenny)
    id 10 name Ubuntu 8.04.2 LTS (hardy)
    id 23 name Windows Server 2003 R2 SP2 x64
    id 24 name Windows Server 2008 SP2 x64
    id 49 name Ubuntu 10.04 LTS (lucid)
    id 14362 name Ubuntu 9.10 (karmic)
    id 62 name Red Hat Enterprise Linux 5.5
    id 53 name Fedora 13
    id 17 name Fedora 12
    id 71 name Fedora 14
    id 31 name Windows Server 2008 SP2 x86
    id 51 name CentOS 5.5
    id 14 name Red Hat Enterprise Linux 5.4
    id 19 name Gentoo 10.1
    id 28 name Windows Server 2008 R2 x64
    id 55 name Arch 2010.05

Oyster only supports Linux images, specifically
Ubuntu 10.10 (maverick).

=item pub_ssh

The public ssh key you would like copied to the
new server's C</root/.ssh/authorized_keys> file
to allow you to ssh in the box without providing
a root password.

=back

=cut
