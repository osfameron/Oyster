use strict;
use warnings;
package Dist::Zilla::App::Command::provision;
BEGIN {
  $Dist::Zilla::App::Command::provision::VERSION = '0.1';
}
# ABSTRACT: release your dist to the CPAN
use Dist::Zilla::App -command;
use Moose;
use Config::Any;
use Hash::Merge 'merge';

sub abstract { 'provision a new Oyster VM' }

sub opt_spec {
  [ 'name=s'     => 'the name of the VM to create' ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla = $self->zilla;

  my $name = $opt->name
    or die "No name provided!";
  my @config_files = ( './oyster.conf' ); # TODO make configurable

  my $cfg = Config::Any->load_files({ files => \@config_files, use_ext => 0 });
  ($cfg) = values %{ $cfg->[0] }; # FIX with ::JFDI or similar

  my $Provision = $cfg->{Provision} or die "No <Provision> section";

  my @hashes = grep $_, $Provision->{Default}, $Provision->{$name}
      or die "No section for <Provision> <$name>, and no <default>";
    
  my %hash = @hashes > 1 ? %{ merge( @hashes ) } : $hashes[0];

  $hash{provision_backend} = delete $hash{type} || 'Rackspace';
  $hash{pub_ssh} ||= "$ENV{HOME}/.ssh/id_rsa.pub";
  $hash{size}    ||= 128;
  $hash{image}   ||= 'meerkat'; # TODO, should this be determined on backend?

  use Oyster::Provision;
  my $server = Oyster::Provision->new(
        name => $name,
        %hash,
  );
  $server->create;
  print "Instance $name created! ($server)\n";
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::App::Command::provision - provision a new Oyster VM

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    TODO

=head1 AUTHOR

CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by CONTRIBUTORS

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

