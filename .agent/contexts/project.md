# Project Context: Golden Image Builder

## Overview
The Golden Image Builder is a multi-os, multi-hypervisor framework designed to generate immutable VM templates securely and reproducibly using HashiCorp Packer.

## Architecture
- **`/os/` directory**: Contains all OS templates. Each OS has a standardized structure:
  - `config.yml`: The default baseline hardware configuration (CPU, memory, disk size).
  - `packer/`: The Packer `.pkr.hcl` files.
  - `scripts/`: Shell or PowerShell provisioning scripts.
  - `unattended/`: OS-specific answer files (`autounattend.xml`, `kickstart.cfg`, `preseed.cfg`).
- **Schemas (`/schema/`)**: JSON schemas that define how YAML configurations must be formatted.
  - `golden-image-config.schema.json`
  - `remote-target-config.schema.json`
  - `upload-config.schema.json`
- **Wrappers**: `golden-image.sh` and `golden-image.ps1` are CLI wrappers that orchestrate Packer with standardized arguments (`--os`, `--virt`, `--mode`, `--remote-config`, `--upload-config`).

## Operating Constraints
- Agents must NOT hallucinate template directories or configuration variables.
- All configurations must be verified against their respective schemas.
- Do not modify existing `.pkr.hcl` files unless explicitly requested. Always validate modifications with `packer validate`.
