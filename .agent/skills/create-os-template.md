# Skill: Create a New OS Template

## Description
When asked to add support for a new Operating System (e.g., Ubuntu, RHEL, AlmaLinux), use this skill to scaffold the directory correctly.

## Steps
1. **Create the OS Directory**: Create a new folder under `/os/` (e.g., `mkdir -p os/ubuntu2204/{packer,scripts,unattended}`).
2. **Scaffold config.yml**: Create `os/<os-name>/config.yml` adhering strictly to `/schema/golden-image-config.schema.json`. Define default CPU, Memory, and Disk layout.
3. **Scaffold Packer Code**: Create `os/<os-name>/packer/variables.pkr.hcl` and `os/<os-name>/packer/<os-name>.pkr.hcl`. Make sure you implement multiple builders (e.g., `qemu`, `virtualbox-iso`, `vsphere-iso`) as requested.
4. **Answer File**: Provide the OS-specific automated installation file (e.g., `user-data` for Ubuntu, `kickstart.cfg` for RedHat) in `os/<os-name>/unattended/`.
5. **Provisioning Scripts**: Add `setup.sh` or `setup.ps1` in `os/<os-name>/scripts/` and map them in your `config.yml` under `modes.base.scripts`.
6. **Validation**: Change directory to `os/<os-name>/packer/` and run `packer fmt .` followed by `packer validate .`.
