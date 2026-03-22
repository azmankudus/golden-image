#!/usr/bin/env bash

set -e

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --list                 List available OS templates"
    echo "  --os <name>            Specify the OS template (e.g., win2022)"
    echo "  --virt <type>          Virtualization option: "
    echo "                           Local: libvirt, virtualbox, vmware-workstation"
    echo "                           Remote: vmware-esxi, vmware-vcenter, proxmox, xcp-ng"
    echo "  --cpu <cores>          Number of CPUs (overrides default)"
    echo "  --memory <mb>          Memory size in MB (overrides default)"
    echo "  --disk-layout <file>   Specify separate YAML file for disk layout (overrides default config.yml)"
    echo "  --mode <type>          Mode to run: base, hardened, vagrant"
    echo "  --help                 Show this help message"
    exit 1
}

if [[ $# -eq 0 ]]; then
    usage
fi

LIST=0
OS=""
VIRT=""
CPU=""
MEMORY=""
DISK_LAYOUT=""
MODE="base"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list) LIST=1; shift ;;
        --os) OS="$2"; shift 2 ;;
        --virt) VIRT="$2"; shift 2 ;;
        --cpu) CPU="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --disk-layout) DISK_LAYOUT="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ $LIST -eq 1 ]]; then
    echo "Available OS templates:"
    ls -1 os/
    exit 0
fi

if [[ -z "$OS" ]]; then
    echo "Error: --os is required"
    usage
fi

if [[ ! -d "os/$OS" ]]; then
    echo "Error: OS template 'os/$OS' not found!"
    exit 1
fi

if [[ -z "$VIRT" ]]; then
    echo "Error: --virt is required"
    usage
fi

echo "Building Golden Image for OS: $OS"
echo "Virtualization: $VIRT"
echo "Mode: $MODE"

PACKER_ARGS=()
if [[ -n "$CPU" ]]; then
    PACKER_ARGS+=("-var" "cpus=$CPU")
    echo "Overrides CPU: $CPU"
fi

if [[ -n "$MEMORY" ]]; then
    PACKER_ARGS+=("-var" "memory=$MEMORY")
    echo "Overrides Memory: $MEMORY"
fi

if [[ -n "$DISK_LAYOUT" ]]; then
    echo "Using disk layout from: $DISK_LAYOUT"
fi

cd "os/$OS/packer"

case "$VIRT" in
    libvirt) BUILDER="qemu" ;;
    virtualbox) BUILDER="virtualbox-iso" ;;
    vmware-workstation) BUILDER="vmware-iso" ;;
    vmware-esxi) BUILDER="vsphere-iso" ;;
    vmware-vcenter) BUILDER="vsphere-iso" ;;
    proxmox) BUILDER="proxmox-iso" ;;
    xcp-ng) BUILDER="xenserver-iso" ;;
    *) BUILDER="$VIRT" ;;
esac

echo "Running: packer build -only=*.$BUILDER.* ${PACKER_ARGS[@]} ."
# Uncomment to execute
# packer build -only="*.$BUILDER.*" "${PACKER_ARGS[@]}" .

echo "Done!"
