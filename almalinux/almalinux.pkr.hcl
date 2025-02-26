packer {
  required_plugins {
    vmware = {
      version = "~> 1"
      source = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "base" {
  iso_url = "iso/AlmaLinux-9.5-x86_64-dvd.iso"
  iso_checksum = "none"
  guest_os_type = ""
  
  ssh_timeout = "30m"
  ssh_username = "user"
  ssh_password = "abcd1234"
  shutdown_command = "echo 'abcd1234' | sudo -S shutdown -P now"

  cpus = 2
  memory = 4096
  disk_size = 102400

  format = "ova"
  network = "hostonly"
  network_adapter_type = "vmxnet3"
  disk_adapter_type ="nvme"
  disk_type_id = "1"

  vmx_data = {
    "cpuid.coresPerSocket" = "2"
  }

  boot_wait            = "5s"
  boot_command         = [
    "<up>",
    "<tab>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg",
    "<enter>",
    "<wait>"
  ]
  http_directory       = "http"
  headless             = false
}

build {
  sources = [
    "source.vmware-iso.base"
  ]
  provisioner "shell" {
    scripts = [
      "script/set-repo.sh"
    ]
  }
}
