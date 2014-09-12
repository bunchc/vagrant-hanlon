# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
  'hanlon' => [1, 100],
  'node'   => [1, 103],
}

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Virtualbox
  config.vm.box = "trusty64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  # VMware Fusion / Workstation
  config.vm.provider "vmware_fusion" do |vmware, override|
    override.vm.box = "trusty64_fusion"
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vmwarefusion.box"
    
    # Fusion Performance Hacks
    vmware.vmx["logging"] = "FALSE"
    vmware.vmx["MemTrimRate"] = "0"
    vmware.vmx["MemAllowAutoScaleDown"] = "FALSE"
    vmware.vmx["mainMem.backing"] = "swap"
    vmware.vmx["sched.mem.pshare.enable"] = "FALSE"
    vmware.vmx["snapshot.disabled"] = "TRUE"
    vmware.vmx["isolation.tools.unity.disable"] = "TRUE"
    vmware.vmx["unity.allowCompostingInGuest"] = "FALSE"
    vmware.vmx["unity.enableLaunchMenu"] = "FALSE"
    vmware.vmx["unity.showBadges"] = "FALSE"
    vmware.vmx["unity.showBorders"] = "FALSE"
    vmware.vmx["unity.wasCapable"] = "FALSE"

    # Memory:
    vmware.vmx["memsize"] = "1024"
    vmware.vmx["numvcpus"] = "1"

  end

  nodes.each do |prefix, (count, ip_start)|
    count.times do |i|
      if prefix == "node"
        hostname = "%s-%02d" % [prefix, (i+1)]
      else
        hostname = "%s" % [prefix, (i+1)]
      end

      config.vm.define "#{hostname}" do |box|

        if prefix == "node"
          box.vm.box = "razor_node"
          box.vm.box_url = "http://openstack.prov12n.com/files/razor_node.box"
          box.vm.provider "vmware_fusion" do |v|
            v.gui = true
          end
        else
          box.vm.network "private_network", ip: "172.16.2.137"
          box.vm.provision :shell, path: "provision.sh"
        end
      end
    end
  end
end