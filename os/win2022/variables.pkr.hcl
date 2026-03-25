# ==============================================================================
# File: variables.pkr.hcl
# Description: Defines the core input parameters and variable types explicitly 
# used within the build.pkr.hcl configuration for validation.
# ==============================================================================

variable "vm_name" {
  type        = string
  description = "Name of the VM to be created."
  default     = "vm.qcow2"
}

variable "setup_iso" {
  type        = string
  description = "Path to the primary Microsoft Windows Server installer ISO file."
  default     = "./iso/dummy.iso"
}
variable "setup_iso_checksum" {
  type        = string
  description = "Path to the primary Microsoft Windows Server installer ISO file."
  default     = "none"
}

variable "floppy_image" {
  type        = string
  description = "Path to the pre-compiled RAW Floppy Image payload governing the specific Server 2022 Edition deployment rules."
  default     = "../../utility/dummy.img"
}

variable "fod_iso" {
  type        = string
  description = "Path to the Windows Server Features on Demand (FoD) ISO containing OpenSSH/extras."
  default     = "../../utility/dummy.iso"
}

variable "virtio_iso" {
  type        = string
  description = "Path to the VirtIO driver stack installer ISO used by QEMU networking and storage."
  default     = "../../utility/dummy.iso"
}

variable "update_iso" {
  type        = string
  description = "Path to the ISO file containing standalone Windows updates (.msu) at the root."
  default     = "../../utility/dummy.iso"
}

variable "extra_iso" {
  type        = string
  description = "Path to the ISO file containing standalone app installers (e.g., Windows Admin Center) at the root."
  default     = "../../utility/dummy.iso"
}

variable "output_dir" {
  type        = string
  description = "Destination folder path containing the resulting golden standard .qcow2 VM artifact."
  default     = "./output/"
}

variable "vcpus" {
  type        = number
  description = "The aggregate virtual CPUs assigned to the VM during the image creation lifecycle."
  default     = 2
}

variable "memory" {
  type        = number
  description = "Amount of volatile memory (in MB) assigned to the VM instance."
  default     = 4096
}

variable "disk_size" {
  type        = string
  description = "Maximum size mapping of the raw standard virtual disk (default expands sparsely)."
  default     = "200g"
}

variable "winrm_username" {
  type        = string
  description = "Standard local administrator account credential identifier used by Packer WinRM Communicator."
  default     = "Administrator"
}

variable "winrm_password" {
  type        = string
  description = "Symmetrical local administrator password generated globally across setup media mapping."
  default     = "A1b2#C3d4$" # Must exactly mirror Autounattend.xml password element.
  sensitive   = true
}

variable "winrm_timeout" {
  type        = string
  description = "Upper-bound fallback deadline before Packer declares the machine completely headless / locked."
  default     = "30m"
}
