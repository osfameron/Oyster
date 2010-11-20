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
