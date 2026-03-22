# Project Context: Golden Image Builder

## Overview
This repository provides a universal, scalable framework for generating immutable Golden VM Images using HashiCorp Packer.

## Supported Virtualization Platforms
- **Local**: `libvirt` (Qemu), `virtualbox`, `vmware-workstation`
- **Remote**: `vmware-esxi` (vSphere), `vmware-vcenter` (vSphere), `proxmox`, `xcp-ng` (XenServer)

## Directory Structure
- `golden-image.sh` / `golden-image.ps1`: The main entrypoint scripts for bash and PowerShell respectively. They accept arguments like `--os`, `--virt`, `--mode`, `--remote-config`, and `--upload-config`.
- `schema/`: Contains JSON schemas for validating configurations.
  - `golden-image-config.schema.json`: Base VM definition (CPU, Memory, Disks).
  - `remote-target-config.schema.json`: Authentication and target location for remote virtualization platforms (vCenter, Proxmox, etc.).
  - `upload-config.schema.json`: Post-build actions for exporting to local folders, SMB, S3, or Vagrant Cloud.
- `os/`: Contains the actual Packer templates. Each OS is a sub-folder.
  - `os/<os-name>/config.yml`: Default VM layout and mode scripts.
  - `os/<os-name>/packer/`: Contains the Packer `.pkr.hcl` source code.
  - `os/<os-name>/scripts/`: Contains the provisioning shell/PowerShell scripts.
  - `os/<os-name>/unattended/`: Contains answer files like `autounattend.xml` or `kickstart.cfg`.

## Modes
- **base**: A minimal, clean installation.
- **hardened**: Locked down and security compliant installation.
- **vagrant**: Image customized for Vagrant usage (e.g., includes `vagrant` user and keys).
