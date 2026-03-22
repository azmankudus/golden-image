# ✨ Golden Image Builder

Welcome to the **Golden Image Builder**! This project provides a universal, scalable framework for generating immutable Golden VM Images across various Operating Systems and Virtualization platforms.

## 🚀 Features

- **Multi-OS Support**: Effortlessly add Windows, Linux, or any custom OS via modular folders.
- **Agnostic Virtualization**: Works flawlessly with:
  - 🖥️ **Local**: Libvirt/Qemu, VirtualBox, VMware Workstation.
  - ☁️ **Remote**: VMware ESXi, VMware vCenter, Proxmox, XCP-ng.
- **Customizable Resources**: Dynamically adjust CPU, Memory, and Disk Layout configurations on the fly.
- **Flexible Modes**:
  - `base`: Minimal, clean installation.
  - `hardened`: Locked down and security compliant.
  - `vagrant`: Readily usable for developers with `vagrant` integrations.
- **Export & Upload**: Automatically copy the resulting image to a local folder, SMB share, AWS S3 bucket, or Vagrant Cloud.
- **Agentic Ready**: Integrated `.agent/` context directory to natively support AI/LLM workflow enhancements.

---

## 📂 Directory Structure

```text
.
├── golden-image.sh           # Main execution script (Linux/macOS)
├── golden-image.ps1          # Main execution script (Windows)
├── .agent/                   # Agentic AI Context & Instructions
├── schema/                   # JSON schemas for configurations
│   ├── golden-image-config.schema.json
│   ├── remote-target-config.schema.json
│   └── upload-config.schema.json
└── os/                       # OS Templates Hub
    └── win2022/              # Example Windows Server 2022 Template
        ├── config.yml        # Default VM definition & Disk Layout
        ├── packer/           # Packer definitions (*.pkr.hcl)
        ├── scripts/          # Provisioning scripts (e.g., setup.ps1)
        └── unattended/       # Answer files (e.g., autounattend.xml)
```

---

## 🛠️ Usage

### Bash (Linux / macOS)

```bash
# List available OS templates
./golden-image.sh --list

# Build a Windows Server 2022 Base Image on Libvirt
./golden-image.sh --os win2022 --virt libvirt --mode base

# Build on a remote vCenter using a custom target config
./golden-image.sh --os win2022 --virt vmware-vcenter --remote-config my-vcenter.json

# Build locally and upload the result to an S3 bucket
./golden-image.sh --os win2022 --virt virtualbox --upload-config s3-upload.yml
```

### PowerShell (Windows)

```powershell
# List available OS templates
.\golden-image.ps1 -List

# Build a Windows Server 2022 Base Image on VMware ESXi
.\golden-image.ps1 -Os win2022 -Virt vmware-esxi -Mode base

# Build with custom resources and upload to SMB
.\golden-image.ps1 -Os win2022 -Virt virtualbox -Cpu 4 -Memory 8192 -UploadConfig smb-share.json
```

---

## ⚙️ Configuration & Disk Layout

Each OS directory (e.g., `os/win2022`) contains a `config.yml` that defines its baseline hardware and build steps. You can override these defaults directly through the CLI or by providing a custom YAML file using the `--disk-layout` (or `-DiskLayout`) parameter.

### Remote Targets
To connect to remote platforms like vSphere or Proxmox, provide a JSON/YAML configuration file using `--remote-config`. This file must conform to `schema/remote-target-config.schema.json`.

### Upload & Export Destinations
To automate the distribution of the final image, provide a JSON/YAML configuration file using `--upload-config`. This file must conform to `schema/upload-config.schema.json` and supports local copying, S3, SMB, and Vagrant Cloud.

### Override ISO & Tools ISO
You can optionally provide dynamic ISOs to override the default OS template ISO or inject an additional Tools ISO (like VMware Tools or VirtualBox Guest Additions).
The scripts support retrieving ISOs from `http/https`, `ftp/sftp`, `s3://`, `smb://`, `file://`, absolute, or relative paths natively:

```bash
# Override the base OS ISO with an S3 bucket source
./golden-image.sh --os win2022 --virt libvirt --iso "s3://my-iso-bucket/windows-2022-custom.iso"

# Inject an additional tools ISO from a local network SMB share
./golden-image.sh --os win2022 --virt vmware-workstation --tools-iso "smb://nas.local/isos/vmware-tools.iso"
```

---

## 🤖 Agentic Use

This repository is optimized for autonomous development! The `.agent/` directory provides AI agents with the correct instructions, skills, and contexts required to maintain and expand this framework. This prevents hallucinated paths and directs the AI strictly toward using `Packer`, the predefined schemas, and the modular `os/` system.

---

*Made with ❤️ for automation engineers.*
