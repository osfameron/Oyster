package Oyster::Deploy::Git;
use strict;
use warnings;

use Git::Wrapper;

our $post_receive = q{
#!/bin/sh
cd ..
env -i git reset --hard HEAD
dzil listdeps | xargs cpanm --local-lib=~/perl5
};

our $post_update = q{
#!/bin/sh
# This rather relies on being an account with permission to do this.
# Who does the script run as?  Presumably the owner of the repo as git will
# use ssh-keys to get onto the server.
#
# Realistically that user needs to be put in /etc/sudoers
#
# user ALL=NOPASSWD: /etc/init.d/lighttpd
#
# Restart server
sudo /etc/init.d/lighttpd restart
};

sub create {
  my $self = shift;
  my $location = shift;

  if( -f $location || -d $location ) {
    die("$location already exists");
  }

  mkdir($location);
  my $git = Git::Wrapper->new($location);
  $git->init();

  open my $fh_post_receive, '>', $git->dir . '/.git/hooks/post-receive'
    or die "Cannot write to " . $git->dir . '/.git/hooks/post-receive' . ": $!";
  print $fh_post_receive $post_receive;
  close $fh_post_receive
    or die "Cannot close " . $git->dir . '/.git/hooks/post-receive' . ": $!";

  open my $fh_post_update, '>', $git->dir . '/.git/hooks/post-update'
    or die "Cannot write to " . $git->dir . '/.git/hooks/post-update' . ": $!";
  print $fh_post_update $post_update;
  close $fh_post_update
    or die "Cannot close " . $git->dir . '/.git/hooks/post-update' . ": $!";

  chmod(0x755, ($git->dir . '.git/hooks/post-receive', $git->dir . '.git/hooks/post-update'));

  return 1;
}


1;
