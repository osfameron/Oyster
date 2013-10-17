
class oyster::perl {
  include perlbrew

  package {'patchperl':
    name => 'libdevel-patchperl-perl',
  }
  
  perlbrew::build {'oyster':
    version => 'perl-5.18.1',
    after => Package['patchperl']
  }
  
  perlbrew::install_cpanm {'oyster':}

  perlbrew::install_module{[
    'Module::Starter',
    'Moo',
    ]:
    perl => 'oyster'
  }
}