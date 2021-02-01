locals {
  cpus = vault("/secret/data/packer_build/xoa_basic", "cpus")
  disk_size = vault("/secret/data/packer_build/xoa_basic", "disk_size")
  memory_size = vault("/secret/data/packer_build/xoa_basic", "memory_size")
  checksum = vault("/secret/data/packer_build/xoa_basic", "checksum")
  guest_iso_fullpath = vault("/secret/data/packer_build/xoa_terraform", "guest_iso_fullpath")
  iso_url = vault("/secret/data/packer_build/xoa_basic", "iso_url")
  vm_name = vault("/secret/data/packer_build/xoa_basic", "vm_name")
}

source "virtualbox-iso" "xoa_basic" {
    vm_name = "xoa_basic"
    format = "ova"
    guest_os_type = "RedHat_64"
    iso_url = local.iso_url
    iso_checksum = local.checksum
    boot_command = ["<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks_xoa_basic.cfg<enter><wait>"]
    disk_size = 20480
    http_directory = "http"
    shutdown_command = "/sbin/halt -p"
    ssh_password = "packer"
    ssh_port = 22
    ssh_timeout = "600s"
    ssh_username = "root"
    guest_additions_mode = "disable"
    vboxmanage = [
      [ "modifyvm", "{{.Name}}", "--memory", local.memory_size ],
      [ "modifyvm", "{{.Name}}", "--cpus", local.cpus ],
      [ "modifyvm", "{{.Name}}", "--audio", "none" ]
    ]
  }

build {
  sources = ["sources.virtualbox-iso.xoa_basic"]
  provisioner "file" {
    source = local.guest_iso_fullpath
    destination = "/var/tmp/guest.iso"
  }
  provisioner "shell" {
    inline = [
      "cd /var/tmp && mount -o ro /var/tmp/guest.iso /mnt",
      "cd /mnt/Linux && ./install.sh; cd",
      "umount /mnt && rm /var/tmp/guest.iso",
      "yum -y install net-tools yum-utils python2 sysstat openssl unzip"
    ]
  }
}
