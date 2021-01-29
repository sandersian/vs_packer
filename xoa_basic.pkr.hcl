locals {
  consul_join_ip1 = vault("/secret/data/packer_build/xoa_basic", "consul_join_ip1")
  consul_join_ip2 = vault("/secret/data/packer_build/xoa_basic", "consul_join_ip2")
  consul_join_ip3 = vault("/secret/data/packer_build/xoa_basic", "consul_join_ip3")
  consul_ca_cert_fullpath = vault("/secret/data/packer_build/xoa_basic", "consul_ca_cert_fullpath")
  consul_domain = vault("/secret/data/packer_build/xoa_basic", "consul_domain")
  consul_enc_key = vault("/secret/data/packer_build/xoa_basic", "consul_enc_key")
  consul_token = vault("/secret/data/packer_build/xoa_basic", "consul_token")
  consul_zip_fullpath = vault("/secret/data/packer_build/xoa_basic", "consul_zip_fullpath")
  cpus = vault("/secret/data/packer_build/xoa_basic", "cpus")
  disk_size = vault("/secret/data/packer_build/xoa_basic", "disk_size")
  memory_size = vault("/secret/data/packer_build/xoa_basic", "memory_size")
  checksum = vault("/secret/data/packer_build/xoa_basic", "checksum")
  guest_iso_fullpath = vault("/secret/data/packer_build/xoa_basic", "guest_iso_fullpath")
  iso_url = vault("/secret/data/packer_build/xoa_basic", "iso_url")
  vm_name = vault("/secret/data/packer_build/xoa_basic", "vm_name")
  discovery_init_fullpath = vault("/secret/data/packer_build/xoa_basic", "discovery_init_fullpath")
  consul_service_fullpath = vault("/secret/data/packer_build/xoa_basic", "consul_service_fullpath")
  ansible_keys_fullpath = vault("/secret/data/packer_build/xoa_basic", "ansible_keys_fullpath")
  root_passwd = vault("/secret/data/packer_build/xoa_basic", "root_passwd")
  add_consul_tag_path = vault("/secret/data/packer_build/xoa_basic", "add_consul_tag_path")
}

source "virtualbox-iso" "xoa_basic" {
    vm_name = "xoa_basic"
    format = "ova"
    guest_os_type = "RedHat_64"
    iso_url = local.iso_url
    iso_checksum = local.checksum
    boot_command = ["<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
    disk_size = 20480
    http_directory = "http"
    shutdown_command = "/sbin/halt -p"
    ssh_password = local.root_passwd
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
  provisioner "file" {
    source = local.consul_zip_fullpath
    destination = "/var/tmp/consul.zip"
  }
  provisioner "file" {
    source = local.discovery_init_fullpath
    destination = "/var/tmp/discovery_init.bash"
  }
  provisioner "file" {
    source = local.consul_service_fullpath
    destination = "/usr/local/bin/consul_host_service_create.bash"
  }
  provisioner "file" {
    source = local.consul_ca_cert_fullpath
    destination = "/etc/ssl/certs/local_CA.crt"
  }
  provisioner "file" {
    source = local.ansible_keys_fullpath
    destination = "/var/tmp/ansible_keys"
  }
  provisioner "file" {
    source = local.add_consul_tag_path
    destination = "/usr/local/bin/add_consul_tag.sh"
  }
  provisioner "shell" {
    inline = [
      "cd /var/tmp && mount -o ro /var/tmp/guest.iso /mnt",
      "cd /mnt/Linux && ./install.sh; cd",
      "umount /mnt && rm /var/tmp/guest.iso",
      "yum -y install net-tools yum-utils python2 sysstat openssl unzip",
      "cd /usr/local/bin && unzip /var/tmp/consul.zip",
      "chmod +x /var/tmp/discovery_init.bash",
      "export CONSUL_JOIN_IP1=${local.consul_join_ip1}",
      "export CONSUL_JOIN_IP2=${local.consul_join_ip2}",
      "export CONSUL_JOIN_IP3=${local.consul_join_ip3}",
      "export CONSUL_ENC_KEY=\"${local.consul_enc_key}\"",
      "export CONSUL_TOKEN=${local.consul_token}",
      "export CONSUL_DOMAIN=${local.consul_domain}",
      "/var/tmp/discovery_init.bash",
      "useradd -r -m ansible",
      "echo \"ansible ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/10-ansible",
      "cd ~ansible && mkdir .ssh && chmod 700 .ssh && chown ansible:ansible .ssh",
      "mv /var/tmp/ansible_keys ~ansible/.ssh/authorized_keys && chmod 600 ~ansible/.ssh/authorized_keys && chown ansible:ansible ~ansible/.ssh/authorized_keys"
    ]
  }
}