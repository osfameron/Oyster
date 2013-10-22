
class oyster::packages {

  exec {'apt-get update':
    command => '/usr/bin/apt-get update'
  } ->

  package {[
    'perl',
    'perl-doc',
    ]:
    ensure => 'latest',
  }

}