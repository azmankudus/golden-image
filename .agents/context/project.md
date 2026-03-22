# Golden Image Project Context

This repository is an Infrastructure-as-Code (IaC) framework designed to build immutable, zero-touch Golden Master virtual machine images across multiple Operating Systems and Virtualization platforms using HashiCorp Packer.

## Architecture
- **Wrapper Scripts**: `golden-image.sh` and `golden-image.ps1` are the primary orchestrators.
- **OS Templates**: Located in `os/<os-name>/`. Each module contains:
  - `packer/`: The `.pkr.hcl` files, split by hypervisor type (e.g., `libvirt`, `virtualbox`).
  - `unattended/`: The OS answer files (`autounattend.xml`, `kickstart.cfg`).
  - `scripts/`: Provisioning shell/PowerShell scripts.
- **Schemas**: JSON schemas defining validation boundaries for configs, located in `/schema/`.

## Target Hypervisors
- **Local**: `libvirt` (QEMU), `virtualbox`, `vmware-workstation`
- **Remote**: `vmware-esxi`, `vmware-vcenter`, `proxmox`, `xcp-ng`, `hyperv`