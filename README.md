# ✨ Golden Image Builder

Welcome to the **Golden Image Builder**! This project provides a universal, scalable framework for generating immutable Golden VM Images across various Operating Systems and Virtualization platforms.

## 🚀 Features

- **Multi-OS Support**: Effortlessly add Windows, Linux, or any custom OS via modular folders.
- **Agnostic Virtualization**: Works flawlessly with:
  - 🖥️ **Local**: Libvirt/Qemu, VirtualBox, VMware Workstation.
  - ☁️ **Remote**: VMware ESXi, VMware vCenter, Proxmox, XCP-ng, Hyper-V.
- **Customizable Resources**: Dynamically adjust CPU, Memory, and Disk Layout configurations on the fly.
- **Flexible Modes**:
  - `base`: Minimal, clean installation.
  - `hardened`: Locked down and security compliant.
  - `vagrant`: Readily usable for developers with `vagrant` integrations.
- **Export & Upload**: Automatically copy the resulting image to a local folder, SMB share, AWS S3 bucket, or Vagrant Cloud.
- **Agentic Ready**: Integrated `.agents/` context directory configures autonomous AI/LLM workflow enhancements.

---

## 📂 Directory Structure

```text
.
├── golden-image.sh           # Main execution script (Linux/macOS)
├── golden-image.ps1          # Main execution script (Windows)
├── .agents/                  # Agentic AI Context, Rules & Workflows
├── schema/                   # JSON schemas for configurations
│   ├── golden-image-config.schema.json
│   ├── remote-target-config.schema.json
│   └── upload-config.schema.json
└── os/                       # OS Templates Hub
    └── win2022/              # Windows Server 2022 Golden Image Architecture
        ├── build.pkr.hcl            # Native QEMU / KVM Packer Build Rules
        ├── variables.pkr.hcl        # Input Parameter Definitions
        ├── project.auto.pkrvars.hcl # Environment-Specific Variable Overrides
        ├── driver/                  # Uncompressed Pre-OS VirtIO Boots Drivers
        ├── provision/               # Application-level Internal Bootstrapping
        ├── setup/                   # WinPE OOBE Scripts and Autounattend
        ├── update/                  # Staged .msu Cumulative Patches
        └── extra/                   # External Tool Uploads (e.g. WAC)
```

---

## 🛠️ Usage

### Bash (Linux / macOS)

```bash
# List available OS templates
./golden-image.sh --list

# Build a Windows Server 2022 Base Image on Libvirt
./golden-image.sh --os win2022 --virt libvirt --mode base

# Create Windows Server 2022 Base Image with specific setup mode, ISOs, and custom hardware
# Additionally, display the GUI screen during the build process
./golden-image.sh --os win2022 --virt libvirt --mode base \
  --cpu 1 --memory 1024 --disk-size 204800 \
  --setup-mode "server core" \
  --gui \
  --iso "file:///work/iso/en-us_windows_server_2022_updated_feb_2026_x64_dvd_09efea0d.iso" \
  --tools-iso "file:///work/iso/virtio-win-0.1.285.iso"

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

This repository is optimized for autonomous development! The `.agents/` directory provides AI agents with the correct instructions, skills, and contexts required to maintain and expand this framework. This prevents hallucinated paths and directs the AI strictly toward using `Packer`, the predefined schemas, and the modular `os/` system.

---

*Made with ❤️ for automation engineers.*
