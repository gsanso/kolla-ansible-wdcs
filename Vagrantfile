# -*- mode: ruby -*-
# # vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

# Require YAML module
require 'yaml'

# Read YAML file with box details
servers = YAML.load_file('servers.yml')

# Create boxes
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.ssh.insert_key = false
  config.vm.provision :shell, :inline =>  "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
  config.vm.provision :shell, :inline =>  "apt-get install -y python-minimal"


  # Iterate through entries in YAML file
  servers.each do |servers|
    config.vm.define servers["name"] do |srv|
      srv.vm.box = servers["box"]
      srv.vm.synced_folder '.', '/vagrant', disabled: true
      srv.vm.hostname = servers["name"]


      srv.vm.network    :private_network,
                        :ip => servers["ip"],
                        :libvirt_forward_mode => "veryisolated",
                        :libvirt__dhcp_enabled => false

      srv.vm.network    :public_network,
                        :dev => "br0",
                        :auto_config => false,
                        :mode => "bridge",
                        :type => "bridge"

    srv.vm.provider :libvirt do |libvirt|
        libvirt.driver = "kvm"
	libvirt.cpu_mode = "host-passthrough"
	libvirt.nested = true
        libvirt.memory = servers["ram"]
        #libvirt.cpus = servers["cpus"]
        libvirt.storage :file, :size => servers["disk"], :type => 'qcow2', :cache => 'none'
        #libvirt.storage_pool_name = ENV['STORAGE_POOL']
      end


    end
  end
end
