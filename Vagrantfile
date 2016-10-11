# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
# Update apt and get dependencies
sudo apt-get update
sudo apt-get install -y unzip curl wget vim

# Download Nomad
echo Fetching Nomad...
cd /tmp/
curl -sSL https://releases.hashicorp.com/nomad/0.4.1/nomad_0.4.1_linux_amd64.zip -o nomad.zip
echo Installing Nomad...
unzip nomad.zip
rm -f nomad.zip
sudo chmod +x nomad
sudo mv nomad /usr/bin/nomad
sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

# Install Consul
echo Fetching Consul...
cd /tmp/
curl -sSL https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip -o consul.zip
echo Installing Consul...
unzip consul.zip
rm -f consul.zip
sudo chmod +x consul
sudo mv consul /usr/bin/consul
sudo mkdir /etc/consul.d
sudo chmod a+w /etc/consul.d

SCRIPT

Vagrant.configure(2) do |config|

    # Basic configuration
    config.vm.box = "ubuntu/trusty64"

    # Provisioners
    config.vm.provision "shell", inline: $script
    config.vm.provision "docker"

    # Servers
    1.upto(3) do |i|
        vmName = "nomad-server#{i}"
        vmIP = "192.68.50.1#{i}"
        config.vm.define vmName do |server|
            #server.vm.box = "ubuntu/trusty64"
            server.vm.hostname = vmName
            server.vm.network "private_network", ip: vmIP
        end
    end

    # Clients
    1.upto(1) do |i|
        vmName = "nomad-client#{i}"
        vmIP = "192.68.60.1#{i}"
        config.vm.define vmName do |server|
            #server.vm.box = "ubuntu/trusty64"
            server.vm.hostname = vmName
            server.vm.network "private_network", ip: vmIP
        end
    end

    # Increase memory for Virtualbox
    config.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
    end

    # Increase memory for Parallels Desktop
    config.vm.provider "parallels" do |p, o|
        p.memory = "1024"
    end

    # Increase memory for VMware
    ["vmware_fusion", "vmware_workstation"].each do |p|
        config.vm.provider p do |v|
            v.vmx["memsize"] = "1024"
        end
    end
end