packer {
  required_plugins {
    vmware = {
      version = "~> 1"
      source = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "alma-9_5" {
  output_directory = "output"
  http_directory   = "res"

  vm_name       = "packer-alma-9_5"
  guest_os_type = "almalinux-64"
  headless      = false
  format        = "ova"
  
  iso_url       = "file://E:/iso/AlmaLinux-9.5-x86_64-dvd.iso"
  #iso_checksum  = "file://E:/iso/AlmaLinux-9.5-x86_64-dvd.iso.sha256"
  iso_checksum  = "none"

  cpus      = 2
  memory    = 4096
  disk_size = 102400

  firmware             = "bios"
  network              = "hostonly"
  network_adapter_type = "vmxnet3"
  disk_adapter_type    = "nvme"
  disk_type_id         = "1"

  boot_wait    = "10s"
  boot_command = [
    "<up>",
    "<tab>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg",
    "<enter>",
    "<wait>"
  ]

  communicator     = "ssh"
  ssh_timeout      = "30m"
  ssh_username     = "Administrator"
  ssh_password     = "P@ssw0rd"
  
  shutdown_timeout = "30m"
  shutdown_command = "echo 'P@ssw0rd' | sudo -S shutdown -P now"
}

build {
  sources = [
    "source.vmware-iso.alma-9_5"
  ]

  provisioner "shell" {
    environment_vars = [
      "PACKER_BUILD_VERSION=1.0.0"
    ]
    scripts = [
      "res/provision.sh"
    ]
  }

  post-processor "shell-local" {
    inline = ["vmrun -T ws deleteVM output/packer-alma-9_5.vmx"]
  }
}
