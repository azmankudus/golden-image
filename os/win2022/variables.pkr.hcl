# ==============================================================================
# File: variables.pkr.hcl
# Description: Defines the core input parameters and variable types explicitly 
# used within the build.pkr.hcl configuration for validation.
# ==============================================================================

variable "setup_iso" {
  type        = string
  description = "Path to the primary Microsoft Windows Server installer ISO file."
  default     = "./iso/en-us_windows_server_2022_x64_dvd_620d7eac.iso"
}

variable "fod_iso" {
  type        = string
  description = "Path to the Windows Server Features on Demand (FoD) ISO containing OpenSSH/extras."
  default     = "./iso/20348.1.210507-1500.fe_release_amd64fre_SERVER_LOF_PACKAGES_OEM.iso"
}

variable "virtio_iso" {
  type        = string
  description = "Path to the VirtIO driver stack installer ISO used by QEMU networking and storage."
  default     = "./iso/virtio-win-0.1.285.iso"
}

variable "driver_dir" {
  type        = string
  description = "Local directory supplying pre-extracted .inf driver payloads mapping to the boot A:\\ virtual floppy."
  default     = "./driver/"
}

variable "update_dir" {
  type        = string
  description = "Local directory supplying .msu patch packages for upload to VM via File provisioner."
  default     = "./update/"
}

variable "extra_dir" {
  type        = string
  description = "Local directory supplying standalone app installers (e.g., Windows Admin Center) to VM."
  default     = "./extra/"
}

variable "script_file" {
  type        = string
  description = "Path to the primary bootstrap PowerShell script (setup.ps1) attached via virtual floppy."
  default     = "./setup/setup.ps1"
}

variable "unattend_file" {
  type        = string
  description = "Path to the autounattend.xml answer file providing native zero-touch rules for Windows setup engine."
  default     = "./setup/autounattend.xml"
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
