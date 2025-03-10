packer {
  required_plugins {
    vmware = {
      version = "~> 1"
      source = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "alma-9_5" {
  vm_name          = "packer-alma-9_5"
  output_directory = "output"
  http_directory   = "res"

  iso_url       = "file://E:/iso/AlmaLinux-9.5-x86_64-dvd.iso"
  #iso_checksum  = "file://E:/iso/AlmaLinux-9.5-x86_64-dvd.iso.sha256"
  iso_checksum  = "none"
  guest_os_type = "almalinux-64"

  cpus      = 2
  memory    = 4096
  disk_size = 102400

  headless             = false
  format               = "ova"
  network              = "hostonly"
  network_adapter_type = "vmxnet3"
  disk_adapter_type    = "nvme"
  disk_type_id         = "1"

  boot_wait            = "5s"
  boot_command         = [
    "<up>",
    "<tab>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg",
    "<enter>",
    "<wait>"
  ]

  ssh_timeout      = "30m"
  ssh_username     = "tempadmin"
  ssh_password     = "abcd1234"
  shutdown_command = "echo 'abcd1234' | sudo -S shutdown -P now"
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
