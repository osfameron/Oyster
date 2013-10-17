# -*- mode: ruby -*-
# vi: set ft=ruby :

def parse_environment(env)
  parsed = { # We may want to change these defaults
    name: "Oyster",
    cpus: "1", 
    memory: "512",
  }
  parsed[:name] = ENV["name"] if ENV["name"]
  begin
    parsed.cpus = Integer(ENV["OYSTER_CPUS"])
  rescue
  end
  begin
    parsed.memory = Integer(ENV["OYSTER_CPUS"])
  rescue
  end
  
  return parsed
end

Vagrant.configure("2") do |config|

  # Do some environment parsing
  args = parse_environment(ENV)
  
  config.vm.box = "ubuntu_1204_amd64"

  # Where to fetch the box from if it isn't installed
  config.vm.box_url = "http://goo.gl/8kWkm"

  # This one is so we can pull packages from apt. Uncomment as necessary
  config.vm.network :public_network #,:netmask => '255.255.254.0' #,:bridge => 'en0'
  # This one is so we have a reliable IP for our VM, even on a corporate network
  config.vm.network :private_network, ip: '10.0.10.46', :netmask => '255.255.255.0'

  # Map this directory and our code directory as shared files
  repo_root = File.expand_path(File.dirname(__FILE__))
  code_root = File.expand_path("~/code/")

  # order: from, to, <flags>
  config.vm.synced_folder repo_root, '/srv/oyster/oyster'
  config.vm.synced_folder code_root, '/srv/oyster/code'

  config.vm.provider :virtualbox do |vb|
    vb.customize [
      "modifyvm", :id,
      "--name",   args[:name],
      "--cpus",   args[:cpus],
      "--memory", args[:memory],
    ]
  end

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "init.pp"
    puppet.module_path = "modules"
  end

end
