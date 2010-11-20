package Oyster::Deploy::Git;

use Moose;
use Git::Wrapper;
use Error::Simple;

use Data::Dumper;
use File::Copy;
use File::ShareDir ':ALL';

sub create {
  my $self = shift;
  my $location = shift;

    
  if( -f $location || -d $location ) {
    Error::Simple->throw("$location already exists");
  }
  
  mkdir($location);
  my $git = Git::Wrapper->new($location);
  
  my $postreceive = module_file('Oyster::Deploy::Git', '../share/deploy/git/post-receive');
  my $postupdate = module_file('Oyster::Deploy::Git', '../share/deploy/git/post-update');
  
  copy($postreceive, ($git->dir . '.git/hooks/')) 
    or Error::Simple->throw('Creating post commit hooks failed.');
  copy($postupdate, ($git->dir . '.git/hooks/')) 
    or Error::Simple->throw('Creating post commit hooks failed.');
  
  chmod(0x755, ('./bin/git/hooks/post-receive', './bin/git/hooks/post-update'));
  
  return 1;
}


1;
