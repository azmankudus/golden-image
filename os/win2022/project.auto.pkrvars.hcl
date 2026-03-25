# ==============================================================================
# File: project.auto.pkrvars.hcl
# Description: This file provides environment-specific override values for 
# Packer variables defined in variables.pkr.hcl. This allows adapting the 
# golden image build paths to different developer machines or CI/CD workspaces.
# ==============================================================================

# ------------------------------------------------------------------------------
# Core Setup Media
# ------------------------------------------------------------------------------
setup_iso  = "/work/installer/winserver2022/iso/en-us_windows_server_2022_x64_dvd_620d7eac.iso"
# fod_iso    = "/work/installer/winserver2022/iso/20348.1.210507-1500.fe_release_amd64fre_SERVER_LOF_PACKAGES_OEM.iso"
virtio_iso = "/work/installer/virtio/virtio-win-0.1.285.iso"

# ------------------------------------------------------------------------------
# Auxiliary Provisioning Assets
# Pre-compiled ISOs containing standalone KBs and binaries (e.g. WAC) to push
# ------------------------------------------------------------------------------
update_iso = "/work/installer/winserver2022/iso/win2022-update-2026-03.iso"
extra_iso  = "/work/installer/winserver2022/iso/win2022-extra-2026-03-25.iso"

# ------------------------------------------------------------------------------
# Artifact Output Configuration
# ------------------------------------------------------------------------------
output_dir = "/work/golden-image/win2022/output/"

# ------------------------------------------------------------------------------
# Hardware Topology (vCPUs and RAM matching builder host capabilities)
# ------------------------------------------------------------------------------
vcpus      = 2
memory     = 4096
disk_size  = "200g"

# ------------------------------------------------------------------------------
# WinRM Bootstrapper Credentials
# MUST match the username/password embedded in autounattend.xml exactly.
# ------------------------------------------------------------------------------
winrm_username = "Administrator"
winrm_password = "A1b2#C3d4$"
