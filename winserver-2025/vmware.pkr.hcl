packer {
  required_plugins {
    vmware = {
      version = "~> 1"
      source = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "winserver-2025" {
  output_directory = "output"
  http_directory   = "res"

  vm_name       = "packer-winserver-2025"
  guest_os_type = "windows2022srvnext-64"
  headless      = false
  format        = "ova"
  
  iso_url       = "file://E:/iso/en-us_windows_server_2025_x64_dvd_b7ec10f3.iso"
  #iso_checksum  = "file://E:/iso/en-us_windows_server_2025_x64_dvd_b7ec10f3.iso.sha256"
  iso_checksum  = "none"

  cpus      = 2
  memory    = 4096
  disk_size = 102400

  firmware             = "efi"
  network              = "hostonly"
  network_adapter_type = "vmxnet3"
  disk_adapter_type    = "nvme"
  disk_type_id         = "1"
  cdrom_adapter_type   = "sata"
  cd_files             = [ "res/autounattend.xml" ]
  cd_label             = "AUTO_UNATTEND"

  boot_wait    = "3s"
  boot_command = [
    "<enter>"
  ]

  communicator     = "winrm"
  winrm_use_ssl    = true
  winrm_insecure   = true
  winrm_timeout    = "30m"
  winrm_username   = "Administrator"
  winrm_password   = "P@ssw0rd"
  
  shutdown_timeout = "30m"
  shutdown_command = "shutdown /s /t 10 /f"
}

build {
  sources = [
    "source.vmware-iso.winserver-2025"
  ]

  provisioner "powershell" {
    environment_vars = [
      "PACKER_BUILD_VERSION=1.0.0"
    ]
    scripts = [
      "res/provision.ps1"
    ]
  }

  post-processor "shell-local" {
    inline = ["vmrun -T ws deleteVM output/packer-winserver-2025.vmx"]
  }
}
