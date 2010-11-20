package Oyster::Deploy::Git;

use Moose;
use Git::Wrapper;
use Error::Simple;

use Data::Dumper;

sub create {
  my $self = shift;
  my $location = shift;
  
  if( -f $location || -d $location ) {
    Error::Simple->throw("$location already exists");
  }
  
  mkdir($location);
  my $git = Git::Wrapper->new($location);
  
  return 1;
}


1;