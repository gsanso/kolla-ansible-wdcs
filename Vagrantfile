# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configure a new SSH key and config so the operator is able to connect with
# the other cluster nodes.
if not File.file?("./vagrantkey")
  system("ssh-keygen -f ./vagrantkey -N '' -C this-is-vagrant")
end

Vagrant.configure(2) do |config|
  # Para que no haya que autenticar con key
#  config.ssh.insert_key = false
#config.ssh.username = "vagrant"
#config.ssh.password = "vagrant"
  # The base image to use
  # TODO (harmw): something more close to vanilla would be nice, someday.
  config.vm.box = "ubuntu/xenial64"

  # Next to the hostonly NAT-network there is a host-only network with all
  # nodes attached. Plus, each node receives a 3rd adapter connected to the
  # outside public network.
  # TODO (harmw): see if there is a way to automate the selection of the bridge
  # interface.

  my_privatekey = File.read(File.join(File.dirname(__FILE__), "vagrantkey"))
  my_publickey = File.read(File.join(File.dirname(__FILE__), "vagrantkey.pub"))

  # TODO (harmw): This is slightly difficult to read.
  config.vm.provision :shell, :inline => "apt-get install -y python-minimal"
  config.vm.provision :shell, :inline => "mkdir -p /home/vagrant/.ssh && echo '#{my_privatekey}' >> /home/vagrant/.ssh/id_rsa && chmod 600 /home/vagrant/.ssh/*"
 config.vm.provision :shell, :inline => "echo '#{my_publickey}' > /home/vagrant/.ssh/authorized_keys"
 config.vm.provision :shell, :inline => "chmod 600 /home/vagrant/.ssh/authorized_keys"

  config.vm.provision :shell, :inline => "echo 'Host *' > /home/vagrant/.ssh/config"
  config.vm.provision :shell, :inline => "echo StrictHostKeyChecking no >> /home/vagrant/.ssh/config"
  config.vm.provision :shell, :inline => "chown -R vagrant: /home/vagrant/.ssh"


  config.hostmanager.enabled = true
  config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
    if vm.id
      `VBoxManage guestproperty get #{vm.id} "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
    end
  end

  # The operator controls the deployment
  config.vm.define "kolla-deployer" do |deployer|
    deployer.vm.hostname = "kolla-deployer"
    #deployer.vm.provision :shell, path: "bootstrap.sh", args: "operator"
    deployer.vm.network "private_network", ip: "10.1.1.100"
    deployer.vm.network "public_network", ip: "0.0.0.0", bridge: "br0"
    deployer.vm.synced_folder "storage/deployer/", "/data/host", create:"True"
    deployer.vm.synced_folder "storage/shared/", "/data/shared", create:"True"
    deployer.vm.synced_folder ".", "/vagrant", disabled: true
    deployer.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
    end
    deployer.hostmanager.aliases = "kolla-deployer"
  end

# Build compute nodes
  (1..1).each do |i|
    config.vm.define "kolla-cp#{i}" do |compute|
      compute.vm.hostname = "kolla-cp#{i}"
      #compute.vm.provision :shell, path: "bootstrap.sh"
      compute.vm.network "private_network", ip: "10.1.1.13"
      compute.vm.network "public_network", ip: "0.0.0.0", bridge: "br0"
      compute.vm.synced_folder "storage/compute/", "/data/host", create:"True"
      compute.vm.synced_folder "storage/shared/", "/data/shared", create:"True"
      compute.vm.synced_folder ".", "/vagrant", disabled: true
      compute.vm.provider "virtualbox" do |vb|
        vb.memory = 3072
      end
      compute.hostmanager.aliases = "kolla-cp#{i}"
  end
end

# Build controller nodes
  (1..3).each do |i|
    config.vm.define "kolla-ct#{i}" do |controller|
      controller.vm.hostname = "kolla-ct#{i}"
      #support.vm.provision :shell, path: "bootstrap.sh"
      controller.vm.network "private_network", ip: "10.1.1.#{i+9}"
      controller.vm.network "public_network", ip: "0.0.0.0", bridge: "br0"
      controller.vm.synced_folder "storage/support/", "/data/host", create:"True"
      controller.vm.synced_folder "storage/shared/", "/data/shared", create:"True"
      controller.vm.synced_folder ".", "/vagrant", disabled: true
      controller.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
      end
      controller.hostmanager.aliases = "kolla-ct#{i}"


      # TODO: Here we bind local port 8080 to Horizon on support01 only.
      # TODO: Once we implement Horizon behind a VIP, this obviously needs to
      # be changed.
      #if i < 2 then
      #  config.vm.network "forwarded_port", guest: 80, host: 8080
      #end
    end
  end

end
