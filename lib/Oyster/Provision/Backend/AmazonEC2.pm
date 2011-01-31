package Oyster::Provision::Backend::AmazonEC2;
use 5.10.1;
use Moose;
use namespace::autoclean;

with qw(Oyster::Provision::API);

use Net::Amazon::EC2;

sub BUILD {
    my $self = shift;
    $self->config->_image('ami-be6e99d7') unless $self->config->has_image;
}

has ec2_oyster_key => (
    is      => 'rw',
    isa     => 'Str',
    default => 'OysterDefault'
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
        my $result =
          $ec2->create_key_pair( { KeyName => $self->ec2_oyster_key } );

        die $result->errors->[0]->message
          if $result->isa('Net::Amazon::EC2::Errors');
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

        #        KeyName      => $self->ec2_oyster_key,
        ImageId      => $self->image,
        InstanceType => $self->size,
        MinCount     => 1,
        MaxCount     => 1,
    );

    if ( blessed($result) && $result->isa('Net::Amazon::EC2::Errors') ) {
        die $result->errors->[0]->message;
    }

    my $instance_id = $result->instances_set->[0]->instance_id;
    my $instance    = $self->_wait_for_instance($instance_id);
    $self->add_instance($instance);
}

sub _wait_for_instance {
    my ( $self, $instance_id ) = @_;
    confess 'instance_id required' unless defined $instance_id;
    my $name = $self->name;    # cache the name
    my $ec2  = $self->ec2;
    while (1) {
        my $result = $ec2->describe_instances( InstanceId => [$instance_id], );

        if ( blessed($result) && $result->isa('Net::Amazon::EC2::Errors') ) {
            confess $result->errors->[0]->message;
        }
        
        confess "$result isn't a Net::Amaozon::EC2::ReservationInfo"
          unless $result->[0]->isa('Net::Amazon::EC2::ReservationInfo');
          
          
        my $instance = $result->[0]->{instances_set}->[0];
        given ( $instance->instance_state->code ) {
            when (16) { return $instance }
            when (0)  { sleep 1 }
        }
    }
    confess 'Instance never started!';
}

sub delete {
    my $self   = shift;
    my $result = $self->ec2->terminate_instances(
        InstanceId => [ $self->instance->instance_id ] );

    if ( blessed($result) && $result->isa('Net::Amazon::EC2::Errors') ) {
        die $result->errors->[0]->message;
    }

    $self->remove_instance;
}

sub resize { confess "ABSTRACT" }

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
