# ==============================================================================
# File: build.pkr.hcl
# Description: Defines the architectural layout for building the Windows Server
# Golden Image template using QEMU/KVM locally.
# Includes adherence to Zero-Touch boot rules and hardware specifications.
# ==============================================================================

packer {
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "qemu" "win" {
  # ----------------------------------------------------------------------------
  # KVM Architecture & Disk Format
  # Specifies the core hypervisor behavior and primary installation medium mapping.
  # ----------------------------------------------------------------------------
  iso_url          = var.setup_iso
  iso_checksum     = var.setup_iso_checksum
  
  # Requires passing VirtIO BLK drivers during Windows PE setup to successfully find the drive
  disk_interface   = "virtio" 
  disk_size        = var.disk_size
  disk_discard     = "unmap"  # Enable TRIM/UNMAP for thin provisioning / sparse sizing
  disk_cache       = "unsafe" # Maximum speed mapping bypassing host sync operations
  disk_compression = true     # Computes deep block reduction native to QCOW2 upon artifact export
  format           = "qcow2"
  accelerator      = "kvm"    # Linux native hardware acceleration mapping
  output_directory = var.output_dir
  vm_name          = var.vm_name

  # ----------------------------------------------------------------------------
  # CPU, RAM, & Network Assignments
  # ----------------------------------------------------------------------------
  cpus             = var.vcpus
  memory           = var.memory
  headless         = false
  
  # Network specification: Using SLIRP user network to avoid bridge acl mapping errors
  net_device       = "virtio-net"

  # ----------------------------------------------------------------------------
  # BIOS Prompt Interception (Bypass ISO "Press any key...")
  # ----------------------------------------------------------------------------
  boot_wait        = "2s"
  boot_command     = ["<enter><wait><enter><wait><enter><wait><enter><wait><enter>"]

  # ----------------------------------------------------------------------------
  # Secondary ISO Mounting Definitions (WinRM / Extras)
  # Uses the `--drive` explicitly to bypass an old Packer bug that suppresses
  # the primary ISO when `-drive` is detected in QEMU args.
  # ----------------------------------------------------------------------------
  qemuargs = [
    [ "--drive", "file=${var.floppy_image},format=raw,if=floppy" ], # Static Pre-Compiled RAW Floppy Injection mapping bypassing probe warnings
    [ "-device", "ahci,id=ahci0" ],                                 # Inject local AHCI Controller structure to bypass the 4-Device IDE hard limit
    [ "--drive", "file=${var.virtio_iso},media=cdrom,index=1" ],    # VirtIO Guest Tools ISO (Primary IDE Slave)
    [ "--drive", "file=${var.fod_iso},media=cdrom,index=2" ],       # Features on Demand ISO (Secondary IDE Master)
    [ "--drive", "file=${var.update_iso},media=cdrom,if=none,id=update_iso" ],
    [ "-device", "ide-cd,bus=ahci0.0,drive=update_iso" ],           # Custom Windows Update ISO (SATA Port 0)
    [ "--drive", "file=${var.extra_iso},media=cdrom,if=none,id=extra_iso" ],
    [ "-device", "ide-cd,bus=ahci0.1,drive=extra_iso" ]             # Custom Application / Extra ISO (SATA Port 1)
  ]

  # ----------------------------------------------------------------------------
  # Packer WinRM Communicator Handshake
  # Authenticates instantly post-OOBE script (setup.ps1) deploying basic unencrypted auth.
  # ----------------------------------------------------------------------------
  communicator     = "winrm"
  winrm_insecure   = true
  winrm_use_ssl    = false
  winrm_username   = var.winrm_username
  winrm_password   = var.winrm_password
  winrm_timeout    = var.winrm_timeout
}

build {
  sources = ["source.qemu.win"]

  # ============================================================================
  # Stage 1: Installation & Configuration Execution
  # Natively install cumulative patches and standalone gateways synchronously.
  # ============================================================================
  provisioner "powershell" {
    script = "../../provision/install.ps1"
  }

  # ============================================================================
  # Stage 1.5: Optional Vagrant Telemetry and Post-Build Overrides
  # ============================================================================
  provisioner "powershell" {
    inline = var.is_vagrant ? ["powershell.exe -ExecutionPolicy Bypass -File ..\\..\\provision\\vagrant.ps1"] : ["Write-Output 'Skipping Vagrant setup.'"]
  }

  # ============================================================================
  # Stage 2: Artifact Purging & Drive Compaction
  # Shrink and zero out the disk blocks occupied by temporary setup files.
  # ============================================================================
  provisioner "powershell" {
    script = "../../provision/cleanup.ps1"
  }

  # ============================================================================
  # Stage 3: System Reboot Initialization
  # Commits Microsoft's `.msu` update cascades strictly prior to shutting down.
  # ============================================================================
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  post-processor "vagrant" {
    name                = "vagrant-box"
    keep_input_artifact = true
    output              = "${var.output_dir}/${var.vm_name}.box"
  }
}
