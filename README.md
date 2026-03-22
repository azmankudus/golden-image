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
- **Agentic Ready**: Integrated `.agent` configuration to natively support AI/LLM workflow enhancements.

---

## 📂 Directory Structure

```text
.
├── golden-image.sh           # Main execution script (Linux/macOS)
├── golden-image.ps1          # Main execution script (Windows)
├── .agent                    # Agentic AI Context & Guardrails
├── schema/
│   └── golden-image-config.schema.json  # JSON schema for OS configuration
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

# Build with custom resources
./golden-image.sh --os win2022 --virt proxmox --cpu 4 --memory 8192
```

### PowerShell (Windows)

```powershell
# List available OS templates
.\golden-image.ps1 -List

# Build a Windows Server 2022 Base Image on VMware ESXi
.\golden-image.ps1 -Os win2022 -Virt vmware-esxi -Mode base

# Build with custom resources
.\golden-image.ps1 -Os win2022 -Virt virtualbox -Cpu 4 -Memory 8192
```

---

## ⚙️ Configuration & Disk Layout

Each OS directory (e.g., `os/win2022`) contains a `config.yml` that defines its baseline hardware and build steps. You can override these defaults directly through the CLI or by providing a custom YAML file using the `--disk-layout` (or `-DiskLayout`) parameter.

The structure of the `config.yml` is strictly validated by `schema/golden-image-config.schema.json`.

---

## 🤖 Agentic Use

This repository is optimized for autonomous development! The included `.agent` file provisions AI agents with the correct tools, skills, and contexts required to maintain and expand this framework. This prevents hallucinated paths and directs the AI strictly toward using `Packer`, the predefined schema, and the `os/` module system.

---

*Made with ❤️ for automation engineers.*
