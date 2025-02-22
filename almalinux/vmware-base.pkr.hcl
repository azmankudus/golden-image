source "vmware-iso" "base" {
  iso_url = "AlmaLinux-9.5-x86_64-dvd.iso"
  iso_checksum = "AlmaLinux-9.5-x86_64-dvd.iso.sha256"
  
  ssh_username = "user"
  ssh_password = "abcd1234"
  shutdown_command = "shutdown -P now"

  cpus = 2
  memory = 4
  disk_size = 102400

  format = "ova"
  network = "hostonly"
  network_adapter_type = "vmxnet3"
  disk_adapter_type ="nvme"
  disk_type_id = "1"

}

build {
  sources {
    "source.vmware-iso.base"
  }
}