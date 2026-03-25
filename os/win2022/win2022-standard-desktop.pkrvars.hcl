# ==============================================================================
# File: project.auto.pkrvars.hcl
# Description: This file provides environment-specific override values for 
# Packer variables defined in variables.pkr.hcl. This allows adapting the 
# golden image build paths to different developer machines or CI/CD workspaces.
# ==============================================================================

vm_name = "win2022-standard-desktop.qcow2"
floppy_image = "./floppy/win2022-standard-desktop-setup-qemu.img"
output_dir = "/work/golden-image/win2022/win2022-standard-desktop/"
