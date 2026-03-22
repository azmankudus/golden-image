variable "cpus" {
  type    = number
  default = 2
}
variable "memory" {
  type    = number
  default = 4096
}
variable "disk_size" {
  type    = number
  default = 51200
}
variable "iso_url" {
  type    = string
  default = "https://software-download.microsoft.com/download/pr/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
}
variable "iso_checksum" {
  type    = string
  default = "sha256:4f1457c4fe14ce48c9b2324924f33ca4f0470475e661bb16d0033abaf2ebde1e"
}
variable "tools_iso" {
  type    = string
  default = ""
}
variable "output_dir" {
  type    = string
  default = "../../../../output/win2022-virtualbox"
}
variable "setup_mode" {
  type    = string
  default = "standard"
}
variable "vm_name" {
  type    = string
  default = "win2022"
}
variable "net_device" {
  type    = string
  default = "virtio-net"
}
variable "ssh_password" {
  type    = string
  default = "A1b2#C3d4$"
}
variable "headless" {
  type    = bool
  default = true
}
