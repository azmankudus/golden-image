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
  }
}

source "qemu" "win2022" {
  # ----------------------------------------------------------------------------
  # KVM Architecture & Disk Format
  # Specifies the core hypervisor behavior and primary installation medium mapping.
  # ----------------------------------------------------------------------------
  iso_url          = var.setup_iso
  iso_checksum     = "none"
  
  # Requires passing VirtIO drivers during Windows PE setup to successfully find the drive
  disk_interface   = "virtio" 
  disk_size        = var.disk_size
  disk_discard     = "unmap"  # Enable TRIM/UNMAP for thin provisioning / sparse sizing
  disk_cache       = "unsafe" # Maximum speed mapping bypassing host sync operations
  disk_compression = true     # Computes deep block reduction native to QCOW2 upon artifact export
  format           = "qcow2"
  accelerator      = "kvm"    # Linux native hardware acceleration mapping
  output_directory = var.output_dir
  vm_name          = "win2022.qcow2"

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
    [ "-fda", "floppy_image.img" ],                              # Static Pre-Compiled Floppy Injection
    [ "--drive", "file=${var.virtio_iso},media=cdrom,index=2" ], # VirtIO Guest Tools ISO
    [ "--drive", "file=${var.fod_iso},media=cdrom,index=1" ],    # Features on Demand ISO
    [ "--drive", "file=${var.update_iso},media=cdrom,index=3" ], # Custom Windows Update ISO
    [ "--drive", "file=${var.extra_iso},media=cdrom,index=4" ]   # Custom Application / Extra ISO
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
  sources = ["source.qemu.win2022"]

  # ============================================================================
  # Stage 1: Installation & Configuration Execution
  # Natively install cumulative patches and standalone gateways synchronously.
  # ============================================================================
  provisioner "powershell" {
    script = "./provision/install.ps1"
  }

  # ============================================================================
  # Stage 2: Artifact Purging & Drive Compaction
  # Shrink and zero out the disk blocks occupied by temporary setup files.
  # ============================================================================
  provisioner "powershell" {
    script = "./provision/cleanup.ps1"
  }

  # ============================================================================
  # Stage 3: System Reboot Initialization
  # Commits Microsoft's `.msu` update cascades strictly prior to shutting down.
  # ============================================================================
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }
}
