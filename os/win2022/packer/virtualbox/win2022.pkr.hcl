packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "win2022" {
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  output_directory = var.output_dir
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  disk_size        = var.disk_size
  guest_os_type    = "Windows2022_64"
  http_directory   = "../../"
  ssh_username     = "Administrator"
  ssh_password     = "Vagrant1!"
  ssh_timeout      = "1h"
  vm_name          = var.vm_name
  cpus             = var.cpus
  memory           = var.memory
  headless         = var.headless
  floppy_files     = ["../../unattended/autounattend.xml"]
}

build {
  sources = [
    "source.virtualbox-iso.win2022"
  ]
  provisioner "powershell" {
    script = "../../scripts/setup.ps1"
  }
}
