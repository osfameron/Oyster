
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'An incubator for Perls in the Cloud',
  'AUTHOR' => 'osfameron <osfameron@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Temp' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Oyster',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Oyster',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Catalyst::Helper' => '0',
    'Config::Any' => '0',
    'Data::Dumper' => '0',
    'Dist::Zilla::App' => '0',
    'Dist::Zilla::File::FromCode' => '0',
    'Dist::Zilla::File::InMemory' => '0',
    'Dist::Zilla::Role::ModuleMaker' => '0',
    'Dist::Zilla::Role::PluginBundle::Easy' => '0',
    'Error::Simple' => '0',
    'File::Copy' => '0',
    'File::ShareDir' => '0',
    'Git::Wrapper' => '0',
    'MIME::Base64' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Net::Amazon::EC2' => '0',
    'Net::RackSpace::CloudServers' => '0',
    'Net::RackSpace::CloudServers::Server' => '0'
  },
  'VERSION' => '0.001',
  'test' => {
    'TESTS' => 't/Deploy/*.t t/Provision/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package
MY;
use File::ShareDir::Install qw(postamble);


