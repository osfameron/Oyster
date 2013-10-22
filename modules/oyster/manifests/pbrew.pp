
class oyster::pbrew {

  define lib ($lib) {
    exec {
      "oyster_pbrew_lib_${lib}":
      command => "/bin/sh -c 'umask 022; /usr/bin/env PERLBREW_ROOT=${perlbrew::params::perlbrew_root} ${perlbrew::params::perlbrew_bin} lib create oyster@${lib}'",
      user => 'vagrant',
      group => 'vagrant',
      timeout => 10,
      creates => "/home/vagrant/.perlbrew/libs/oyster@${lib}",
      require => Class['perlbrew'],
    }
  }
  
  define install_module($lib) {
    exec {
      "oyster_pbrew_install_module_${name}":
        command => "/bin/sh -c 'umask 022; /usr/bin/env PERLBREW_ROOT=${perlbrew::params::perlbrew_root} PERLBREW_LIB=$lib PERLBREW_PERL=oyster ${perlbrew::params::perlbrew_root}/perls/oyster/bin/cpanm ${name}'",
# Need to figure out a good one for this
#        unless  => "${perlbrew::params::perlbrew_root}/perls/oyster/bin/perl -m${name} -e1",
        timeout => 1800,
    }
  }
}