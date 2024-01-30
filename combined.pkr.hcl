packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = "~> 1"
    }
    sshkey = {
      version = ">= 1.1.0"
      source  = "github.com/ivoronin/sshkey"
    }
  }
}

data "sshkey" "install" {
  name = "mykeypair"
}

source "hyperv-iso" "rhel9" {
  iso_url                = "http://docker1.home.kolstee.net:8081/repository/software/rhel-9.2-x86_64-dvd.iso"
  iso_checksum           = "sha1:0e4bfcdbf367db9abded1954ec8e920db953bf3d"
  disk_size              = 40000
  memory                 = 4096
  vm_name                = "rhel9-build"
  cpus                   = 4
  generation             = 2
  boot_wait              = "5s"
  boot_keygroup_interval = "1s"
  http_content = {
    "/ks.cfg" = templatefile("ks.cfg", { ssh_pubkey_string = data.sshkey.install.public_key })
  }
  boot_command = [
    "<up><up><up>e<down><down><end>",
    " ",
    "ip-dhcp",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    "<f10>"
  ]
  shutdown_command          = "shutdown -h now"
  ssh_timeout               = "20m"
  ssh_username              = "root"
  ssh_private_key_file      = data.sshkey.install.private_key_path
  ssh_clear_authorized_keys = true
  temporary_key_pair_name   = "mykeypair"
}

build {
  sources = ["source.hyperv-iso.rhel9"]
  provisioner "shell" {
    inline = ["echo 'Hello, world!' | sudo tee /root/hello.txt"]
  }
}