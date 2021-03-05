## Basic Packer w/CentOS7 and Virtualbox

### Why?
This is a work around since the current packer module for XenServer/XCP-ng doesn't support the VNC protocol on the most recent version of the hypervisor. After you get an OVA you have to import it to the XenServer/XCP-ng environment manually and rebuild the initramfs. Then you can use it as a template in XenServer/XCP-ng.

This should create an OVA output of a fairly minimal VM instance w/XCP-ng Guest Extensions installed.

There's no way I could find to get XenServer/XCP-ng to make mods to the VM via the guest additions. So, this will also install Consul, join the cluster defined, and create a service derived by the VMs name while setting the hostname to that same value.

A few extra packages will be installed and a yum update will be run before the OVA is created.

We assume you have VirtualBox and Hashicorp Packer installed.

Tested with the following:
* Packer v1.6.6
* VirtualBox v6.1
