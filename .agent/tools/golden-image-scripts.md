# Golden Image Wrapper Scripts

## Description
This repository utilizes standard bash and PowerShell scripts to orchestrate the HashiCorp Packer execution. These are the primary tools you should use (or instruct the user to use) when building images.

## Scripts
- **Linux/macOS**: `./golden-image.sh`
- **Windows**: `.\golden-image.ps1`

## Common Arguments
- `--list` / `-List`: List available OS templates located in `/os/`.
- `--os` / `-Os`: The template to build (e.g., `win2022`). Must match a folder name in `/os/`.
- `--virt` / `-Virt`: The target hypervisor.
  - Local: `libvirt`, `virtualbox`, `vmware-workstation`
  - Remote: `vmware-esxi`, `vmware-vcenter`, `proxmox`, `xcp-ng`
- `--mode` / `-Mode`: Execution mode. Defaults to `base`. Other options: `hardened`, `vagrant`.
- `--remote-config` / `-RemoteConfig`: A JSON/YAML file pointing to remote target credentials and specifications.
- `--upload-config` / `-UploadConfig`: A JSON/YAML file for post-build artifact uploads (S3, SMB, Local, Vagrant Cloud).

## Best Practices
Always check `--list` first if you are unsure which OS templates are actively supported.
