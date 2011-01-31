package Oyster::Provision::Backend::Rackspace;
use Moose;
use namespace::autoclean;

use Net::RackSpace::CloudServers;
use Net::RackSpace::CloudServers::Server;
use MIME::Base64;

with qw(Oyster::Provision::API);

has '_rs' => (
    is      => 'ro',
    isa     => 'Net::RackSpace::CloudServers',
    lazy    => 1,
    builder => '_build_rs',
);

sub _build_rs {
    my $self = shift;
    my $rs   = Net::RackSpace::CloudServers->new(
        user => $self->api_username,
        key  => $self->api_password,
    );
    $rs;
}

sub create {
    my $self = shift;

    die "Rackspace Provisioning backend requires a server name\n" if !defined $self->name;

    # Do nothing if the server named $self->name already exists
    return if scalar grep { $_->name eq $self->name } $self->_rs->get_server();

    # Validate size and image
    {
        die "Rackspace Provisioning backend requires a server image\n"  if !defined $self->image;
        my @allowed_images = $self->_rs->get_image();
        my $image_id = $self->image;
        if ( !scalar grep { $_->{id} eq $image_id } @allowed_images ) {
            die "Rackspace Provisioning backend requires a valid image id\nValid images:\n",
            (map { sprintf("id %-10s -- %s\n", $_->{id}, $_->{name}) } @allowed_images),
            "\n";
        }

        die "Rackspace Provisioning backend requires a server size\n"  if !defined $self->size;
        my @allowed_flavors = $self->_rs->get_flavor();
        my $flavor_id = $self->size;
        if ( !scalar grep { $_->{id} eq $flavor_id } @allowed_flavors ) {
            die "Rackspace Provisioning backend requires a valid size id\nValid flavors:\n",
                (map { sprintf("id %-10s -- %s\n", $_->{id}, $_->{name}) } @allowed_flavors),
                "\n";
        }
    }

    # Check the ssh pub key exists and is <10K
    die "SSH pubkey needs to exist" if !-f $self->pub_ssh;
    my $pub_ssh = do {
        local $/ = undef;
        open my $fh, '<', $self->pub_ssh
          or die "Cannot open ", $self->pub_ssh, ": $!";
        my $_data = <$fh>;
        close $fh or die "Cannot close ", $self->pub_ssh, ": $!";
        $_data;
    };
    die "SSH pubkey needs to be < 10KiB" if length $pub_ssh > 10 * 1024;

    # Build the server
    my $server = Net::RackSpace::CloudServers::Server->new(
        cloudservers => $self->_rs,
        name         => $self->name,
        flavorid     => $self->size,
        imageid      => $self->image,
        personality  => [
            {
                path     => '/root/.ssh/authorized_keys',
                contents => encode_base64($pub_ssh),
            },
        ],
    );
    my $newserver = $server->create_server;
    warn "Server root password: ", $newserver->adminpass, "\n";

    do {
        $| = 1;
        my @tmpservers = $self->_rs->get_server_detail();
        $server = ( grep { $_->name eq $self->name } @tmpservers )[0];
        print "\rServer status: ", ( $server->status || '?' ), " progress: ",
          ( $server->progress || '?' );
        if ( ( $server->status // '' ) ne 'ACTIVE' ) {
            print " sleeping..";
            sleep 2;
        }
    } while ( ( $server->status // '' ) ne 'ACTIVE' );

    warn "Server public IP are: @{$server->public_address}\n";
    my $public_ip  = (@{$server->public_address})[0];
    my $servername = sprintf("oyster-%s", $self->name);

    # Adds the server's name to the user's ~/.ssh/config
    # using oyster-servername
    {
        open my $fh, '>>', "$ENV{HOME}/.ssh/config"
            or die "Error opening $ENV{HOME}/.ssh/config for appending: $!";
        my $template = "\nHost %s\n" .
            "    User root\n" .
            "    Port 22\n" .
            "    Compression yes\n" .
            "    HostName %s\n" .
            "\n";
        print $fh sprintf($template, $servername, $public_ip);
        close $fh or die "Error closing $ENV{HOME}/.ssh/config: $!";
    }

    # Connect to server and execute installation routines -- unlike EC2 each
    # server needs instantiated from scratch every time
    warn "Initializing the server...";
    $self->initialise();

    warn "Deploying the application...";
    $self->deploy();

}

sub initialise {
    my $self = shift;
    my $servername = sprintf("oyster-%s", $self->name);

    # Adds the server's key to the user's ~/.ssh/authorized_keys
    # FIXME there must be a better way?!
    warn "Adding SSH key for $servername to ~/.ssh/authorized_keys\n";
    qx{/usr/bin/ssh -o StrictHostKeyChecking=no -l root $servername 'echo oyster'};

    # FIXME should call the module which does the installation...
    warn "Installing wget, lighttpd and git...\n";
    print qx{/usr/bin/ssh -l root $servername 'LC_ALL=C /usr/bin/apt-get install --yes wget lighttpd git git-core'};
    print qx{/usr/bin/ssh -l root $servername 'LC_ALL=C /usr/sbin/service lighttpd stop'};
    warn "Adding user perloyster...\n";
    print qx{/usr/bin/ssh -l root $servername 'LC_ALL=C /usr/sbin/adduser --disabled-password --gecos "Perl Oyster" perloyster'};
    warn "Copying keys to ~perloyster...\n";
    print qx{/usr/bin/ssh -l root $servername 'LC_ALL=C /bin/mkdir ~perloyster/.ssh/'};
    print qx{/usr/bin/ssh -l root $servername 'LC_ALL=C /bin/cp ~/.ssh/authorized_keys ~perloyster/.ssh/'};
    print qx{/usr/bin/ssh -l root $servername 'LC_ALL=C /bin/chown --recursive perloyster ~perloyster/.ssh/'};
    warn "Making perloyster readable...\n";
    print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /bin/chmod a+r ~perloyster/'};
    #warn "Installing cpanminus...\n";
    #print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /usr/bin/wget --no-check-certificate http://xrl.us/cpanm ; chmod +x cpanm'};
    #warn "Installing prerequisites for Oyster::Deploy::Git...\n";
    #print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C ./cpanm --local-lib=~/perl5 App::cpanminus Dist::Zilla'};
    warn "Getting and unpacking base system...\n";
    print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /usr/bin/wget --no-check-certificate https://darkpan.com/files/oyster-prereqs-20101122-2217.tgz'};
    print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /bin/tar xvf oyster-prereqs-20101122-2217.tgz'};
    print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /bin/echo export PERL5LIB="/home/perloyster/perl5/lib/perl5:/home/perloyster/perl/lib/perl5/x86_64-linux-gnu-thread-multi" >> ~/.bashrc'};
    print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /bin/echo export PATH="/home/perloyster/perl5/bin:\$PATH" >> ~/.bashrc'};

    warn "Pushing and unpacking Oyster::Deploy::Git...\n";
    print qx{/usr/bin/ssh -l perloyster $servername 'LC_ALL=C /bin/mkdir -p perl5/lib/perl5/Oyster/Deploy'};
    print qx{/usr/bin/scp lib/Oyster/Deploy/Git.pm perloyster\@$servername:perl5/lib/perl5/Oyster/Deploy/};
}

sub deploy {
    my $self = shift;
    my $servername = sprintf("oyster-%s", $self->name);
    warn "Deploying application to $servername...\n";
    print qx{/usr/bin/ssh -l perloyster $servername "perl -MOyster::Deploy::Git -le'\$g=Oyster::Deploy::Git->new;\$g->deploy(q,/home/perloyster/oyster,)'"};
}


sub delete {
    my $self = shift;

    # Die if the server named $self->name already exists
    my ($server) = grep { $_->name eq $self->name } $self->_rs->get_server();
    die "No such server: ", $self->name if !$server;

    # Goodbye cruel user!
    $server->delete_server();
}

sub resize {
    my $self = shift;
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

=item api_username

The rackspace API username, or C<$ENV{RACKSPACE_USER}> will be used if that is
not given

=item password

This is your rackspace API Key

The rackspace API key, or C<$ENV{RACKSPACE_KEY}> will be used if that is not
given

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
