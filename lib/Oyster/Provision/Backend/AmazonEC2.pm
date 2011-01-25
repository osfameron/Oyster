package Oyster::Provision::Backend::AmazonEC2;
use Moose;
use namespace::autoclean;

use Net::Amazon::EC2;

has ec2_oyster_key => (
    is      => 'rw',
    isa     => 'Str',
    default => 'OysterDefault'
);

has image => (
    isa     => 'Str',
    is      => 'ro',
    default => 'ami-be6e99d7'
);

has ec2 => (
    isa     => 'Net::Amazon::EC2',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_ec2'
);

sub _build_ec2 {
    my $self = shift;

    my $ec2 = Net::Amazon::EC2->new(
        AWSAccessKeyId  => $self->api_username,
        SecretAccessKey => $self->api_password,
    );

    my $key_pairs =
      $ec2->describe_key_pairs( { KeyName => $self->ec2_oyster_key } );

    unless ( defined($key_pairs) ) {
        printf( "Creating %s pair\n", $self->ec2_oyster_key );
        $ec2->create_key_pair( { KeyName => $self->ec2_oyster_key } );
    }

    return $ec2;
}

has instance => (
    isa     => 'Object',
    reader  => 'instance',
    writer  => 'add_instance',
    clearer => 'remove_instance'
);

sub create {
    my $self = shift;

    # Start 1 new instance from AMI: ami-XXXXXXXX
    my $result = $self->ec2->run_instances(
        KeyName      => $self->ec2_oyster_key,
        ImageId      => $self->image,
        InstanceType => $self->size,
        MinCount     => 1,
        MaxCount     => 1,
    );

    die $result->errors->[0]->message
      if $result->isa('Net::Amazon::EC2::Errors');

    my $instance_id = $result->instances_set->[0]->instance_id;

    my $instance = $self->_wait_for_instance($instance_id);

    $self->add_instance($instance);
}

sub _wait_for_instance {
    my ( $self, $instance_id ) = @_;
    confess 'instance_id required' unless defined $instance_id;
    my $name = $self->name;    # cache the name
    for ( 1 .. 10 ) {          # XXX: try 10 times before giving up
        my $result =
          $self->ec2->describe_instances( InstanceId => [$instance], );

        confess $result->errors->[0]->message
          if $result->isa('Net::Amazon::EC2::Errors');

        $result->[0]->isa('Net::Amazon::EC2::ReservationInfo')
          or confess "$result isn't a Net::Amaozon::EC2::ReservationInfo";

        my @found = map { @{ $_->instances_set } }
          grep {
            grep { $_->group_id eq $name }
              @{ $_->group_set }
          } @{$result};

        if ( grep { $_->instance_state->code == 0 } @found ) {
            sleep 1;
        }
        @found = grep { $_->instance_state->code == 16 } @found;
        next unless scalar @found == 1;
        return $found[0];
    }
    confess 'Instance never started!';
}

sub delete {
    my $self = shift;
    $self->ec2->terminate_instances(
        InstanceId => [ $self->instance->instance_id ] );

    confess $result->errors->[0]->message
      if $result->isa('Net::Amazon::EC2::Errors');

    $self->remove_instance;
}

1;

__END__

=head1 NAME

Oyster::Provision::AmazonEC2 -- Provision your Oyster on Amazon EC2

=head1 SYNOPSIS

Use the Amazon backend on your Oyster configuration file

=head1 REQUIRED PARAMETERS

The following are required to instantiate a backend:

=over

=item name

The name of your new/existing rackspace server.

pub_ssh

This is a key name to pass to EC2 

=item size

=item image

=item pub_ssh

The public ssh key you would like copied to the
new server's C</root/.ssh/authorized_keys> file
to allow you to ssh in the box without providing
a root password.

=back

=cut
