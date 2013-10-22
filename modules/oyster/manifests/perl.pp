
class oyster::perl {
  include perlbrew
  
  class {'oyster::pbrew':}

  package {'patchperl':
    name => 'libdevel-patchperl-perl',
  } ->
  
  perlbrew::build {'oyster':
    version => 'perl-5.18.1',
  } ->
  
  perlbrew::install_cpanm {'oyster':} ->

  oyster::pbrew::lib {'oyster':
    lib => 'oyster'
  } ->
  
  oyster::pbrew::install_module {'Acme::Code::Police':
    lib => 'oyster',
  }

}