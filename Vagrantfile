# -*- mode: ruby -*-
# vi: set ft=ruby :

def parse_environment(env)
  parsed = { # We may want to change these defaults
    name: "Oyster",
    gui: false, # Whether to show a GUI
    cpus: "1", # Number of CPUs
    memory: "512", # Megabytes
    cpulimit: "0", # Maximum % of CPU used
  }

  parsed[:name] = ENV["name"] if ENV["name"]
  parsed[:gui] = true if ENV.has_key?("OYSTER_GUI") and ENV['OYSTER_GUI']

  begin
    parsed[:cpus] = Integer(ENV["OYSTER_CPUS"]).to_s
  rescue
  end

  begin
    parsed[:memory] = Integer(ENV["OYSTER_CPUS"]).to_s
  rescue
  end

  begin
    parsed[:cpulimit] = Integer(ENV["OYSTER_CPULIMIT"]).to_s
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
    vb.gui = args[:gui]
    custs = [
      "modifyvm", :id,
      "--name",   args[:name],
      "--cpus",   args[:cpus],
      "--memory", args[:memory],
    ]
    custs.push("--cpuexecutioncap", args[:cpulimit]) if args[:cpulimit]
    vb.customize custs
  end

  config.vm.provider :vmware_fusion do |vf, override|
    vf.gui = args[:gui]
    vf.vmx['displayName'] = args[:name]
    vf.vmx['memsize'] = args[:memory]
    vf.vmx['numvcpus'] = args[:cpus]
    override.vm.box = "precise64_vmware"
    override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
  end

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "init.pp"
    puppet.module_path = "modules"
  end

end
