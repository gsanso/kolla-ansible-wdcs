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

  # Iterate through entries in YAML file
  servers.each do |servers|
    config.vm.define servers["name"] do |srv|
      srv.vm.box = servers["box"]
      srv.vm.synced_folder '.', '/vagrant', disabled: true
      srv.vm.hostname = servers["name"]

      srv.vm.network    :private_network,
                        :ip => servers["ip"]
                        #:auto_config => false
                        #:libvirt__dhcp_enabled => false


      srv.vm.network    :private_network,
                        :ip => servers["ip"]
                        #:auto_config => false
                        #:libvirt__dhcp_enabled => false


      srv.vm.provider :libvirt do |libvirt|
        libvirt.memory = servers["ram"]
        #libvirt.cpus = servers["cpus"]
        libvirt.machine_virtual_size = servers["disk"]
      end

      # Configure the proper routes, because vagrant is not intelligent enough to do it
      # (vagrant sees two nics and chooses the ethernet connection to be the right one)
      #srv.vm.provision "shell", run: "always", inline: "route del default gw 192.168.121.1”
      #srv.vm.provision "shell", run: "always", inline: "route add default gw 172.16.0.1"

    end
  end
end
