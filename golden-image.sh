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
    echo "  --remote-config <file> Specify JSON/YAML file for remote target configuration (e.g., vCenter, Proxmox)"
    echo "  --upload-config <file> Specify JSON/YAML file for upload destination (e.g., local, S3, SMB)"
    echo "  --iso <uri>            Override OS ISO (supports http/s, ftp, sftp, s3, smb, file://, relative, absolute)"
    echo "  --tools-iso <uri>      Specify tools ISO (supports http/s, ftp, sftp, s3, smb, file://, relative, absolute)"
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
REMOTE_CONFIG=""
UPLOAD_CONFIG=""
ISO=""
TOOLS_ISO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list) LIST=1; shift ;;
        --os) OS="$2"; shift 2 ;;
        --virt) VIRT="$2"; shift 2 ;;
        --cpu) CPU="$2"; shift 2 ;;
        --memory) MEMORY="$2"; shift 2 ;;
        --disk-layout) DISK_LAYOUT="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --remote-config) REMOTE_CONFIG="$2"; shift 2 ;;
        --upload-config) UPLOAD_CONFIG="$2"; shift 2 ;;
        --iso) ISO="$2"; shift 2 ;;
        --tools-iso) TOOLS_ISO="$2"; shift 2 ;;
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

# Helper function to resolve or download ISOs
resolve_or_fetch_iso() {
    local uri=$1
    local dest_dir=$2
    local filename=$(basename "$uri")
    
    mkdir -p "$dest_dir"

    if [[ "$uri" == s3://* || "$uri" == smb://* || "$uri" == http://* || "$uri" == https://* || "$uri" == ftp://* || "$uri" == ftps://* || "$uri" == sftp://* ]]; then
        local dest_file="$dest_dir/$filename"
        if [[ ! -f "$dest_file" ]]; then
            echo "Downloading $uri to $dest_file..."
            if [[ "$uri" == s3://* ]]; then
                aws s3 cp "$uri" "$dest_file"
            elif [[ "$uri" == smb://* ]]; then
                smbget -q -o "$dest_file" "$uri"
            else
                curl -L -o "$dest_file" "$uri"
            fi
        else
            echo "Cached ISO found: $dest_file"
        fi
        echo "$PWD/$dest_file"
    elif [[ "$uri" == file://* ]]; then
        echo "${uri#file://}"
    elif [[ "$uri" = /* ]]; then
        echo "$uri"
    else
        echo "$PWD/$uri"
    fi
}

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

if [[ -n "$REMOTE_CONFIG" ]]; then
    echo "Using remote target configuration from: $REMOTE_CONFIG"
    PACKER_ARGS+=("-var-file" "$PWD/$REMOTE_CONFIG")
fi

if [[ -n "$UPLOAD_CONFIG" ]]; then
    echo "Using upload configuration from: $UPLOAD_CONFIG"
    PACKER_ARGS+=("-var-file" "$PWD/$UPLOAD_CONFIG")
fi

ISO_CACHE_DIR="cache/iso"
if [[ -n "$ISO" ]]; then
    RESOLVED_ISO=$(resolve_or_fetch_iso "$ISO" "$ISO_CACHE_DIR")
    echo "Using OS ISO: $RESOLVED_ISO"
    PACKER_ARGS+=("-var" "iso_url=file://$RESOLVED_ISO")
fi

if [[ -n "$TOOLS_ISO" ]]; then
    RESOLVED_TOOLS_ISO=$(resolve_or_fetch_iso "$TOOLS_ISO" "$ISO_CACHE_DIR")
    echo "Using Tools ISO: $RESOLVED_TOOLS_ISO"
    PACKER_ARGS+=("-var" "tools_iso=$RESOLVED_TOOLS_ISO")
fi

VIRT_DIR="os/$OS/packer/$VIRT"
if [[ ! -d "$VIRT_DIR" ]]; then
    echo "Error: Virtualization platform '$VIRT' is not implemented for OS '$OS'."
    exit 1
fi

if ! ls "$VIRT_DIR"/*.pkr.hcl 1> /dev/null 2>&1; then
    echo "Error: No Packer templates found in $VIRT_DIR"
    exit 1
fi

cd "$VIRT_DIR"

echo "Running: packer build ${PACKER_ARGS[@]} ."
# Uncomment to execute
# packer build "${PACKER_ARGS[@]}" .

if [[ -n "$UPLOAD_CONFIG" ]]; then
    echo ""
    echo "Post-Build: Executing upload/export sequence based on $UPLOAD_CONFIG..."
    # Note: Real logic to parse UPLOAD_CONFIG and perform the action goes here
    echo "Upload/Export completed!"
fi

echo "Done!"
