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
  # Unattended Configuration Payload
  # Using floppy mapping (A:\) avoids CD-ROM multi-drive scanning conflicts and
  # instantly supplies Autounattend.xml to the Windows setup environment natively.
  # ----------------------------------------------------------------------------
  floppy_files     = [
    var.unattend_file,
    var.script_file
  ]
  
  # ----------------------------------------------------------------------------
  # Pre-OS Driver Injection
  # Extracts the core boot-critical VirtIO components (Viostor/Vioscsi/etc.)
  # Windows PE universally scopes the root A:\ directory for valid .inf files. 
  # DO NOT load massive gigabyte payloads into the floppy; it has a rigid 1.44MB cap.
  # ----------------------------------------------------------------------------
  floppy_dirs      = [var.driver_dir]

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
    [ "--drive", "file=${var.virtio_iso},media=cdrom,index=2" ], # VirtIO Guest Tools ISO
    [ "--drive", "file=${var.fod_iso},media=cdrom,index=1" ]    # Features on Demand ISO
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
  # Stage 1: Preparation
  # Prepare the internal VM temporary directories for ingesting deployment assets.
  # ============================================================================
  provisioner "powershell" {
    script = "./provision/prepare.ps1"
  }

  # ============================================================================
  # Stage 2: In-Flight Data Transfer
  # Move the extracted Microsoft Updates (.msu) and auxiliary installers (WAC).
  # ============================================================================
  provisioner "file" {
    source      = var.update_dir
    destination = "C:\\Temp\\update"
  }

  provisioner "file" {
    source      = var.extra_dir
    destination = "C:\\Temp\\extra"
  }

  # ============================================================================
  # Stage 3: Installation & Configuration Execution
  # Natively install cumulative patches and standalone gateways synchronously.
  # ============================================================================
  provisioner "powershell" {
    script = "./provision/install.ps1"
  }

  # ============================================================================
  # Stage 4: Artifact Purging & Drive Compaction
  # Shrink and zero out the disk blocks occupied by temporary setup files.
  # ============================================================================
  provisioner "powershell" {
    script = "./provision/cleanup.ps1"
  }

  # ============================================================================
  # Stage 5: System Reboot Initialization
  # Commits Microsoft's `.msu` update cascades strictly prior to shutting down.
  # ============================================================================
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }
}
