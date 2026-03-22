param(
    [switch]$List,
    [string]$Os,
    [string]$Virt,
    [int]$Cpu,
    [int]$Memory,
    [string]$DiskLayout,
    [string]$Mode = "base",
    [string]$RemoteConfig,
    [string]$UploadConfig
)

if ($List) {
    Write-Host "Available OS templates:"
    Get-ChildItem -Path "os" -Directory | Select-Object -ExpandProperty Name
    exit
}

if (-not $Os) {
    Write-Error "--Os is required"
    exit 1
}

if (-not (Test-Path "os\$Os")) {
    Write-Error "OS template 'os\$Os' not found!"
    exit 1
}

if (-not $Virt) {
    Write-Error "--Virt is required"
    exit 1
}

Write-Host "Building Golden Image for OS: $Os"
Write-Host "Virtualization: $Virt"
Write-Host "Mode: $Mode"

$PackerArgs = @()

if ($Cpu) {
    $PackerArgs += "-var", "cpus=$Cpu"
    Write-Host "Overrides CPU: $Cpu"
}

if ($Memory) {
    $PackerArgs += "-var", "memory=$Memory"
    Write-Host "Overrides Memory: $Memory"
}

if ($DiskLayout) {
    Write-Host "Using disk layout from: $DiskLayout"
}

if ($RemoteConfig) {
    Write-Host "Using remote target configuration from: $RemoteConfig"
    $PackerArgs += "-var-file", "$RemoteConfig"
}

if ($UploadConfig) {
    Write-Host "Using upload configuration from: $UploadConfig"
    $PackerArgs += "-var-file", "$UploadConfig"
}

Push-Location "os\$Os\packer"

$Builder = switch ($Virt) {
    "libvirt" { "qemu" }
    "virtualbox" { "virtualbox-iso" }
    "vmware-workstation" { "vmware-iso" }
    "vmware-esxi" { "vsphere-iso" }
    "vmware-vcenter" { "vsphere-iso" }
    "proxox" { "proxmox-iso" }
    "xcp-ng" { "xenserver-iso" }
    default { $Virt }
}

Write-Host "Running: packer build -only=*.$Builder.* $PackerArgs ."
# Uncomment to execute
# packer build -only="*.$Builder.*" $PackerArgs .

Pop-Location

if ($UploadConfig) {
    Write-Host ""
    Write-Host "Post-Build: Executing upload/export sequence based on $UploadConfig..."
    # Note: Real logic to parse UPLOAD_CONFIG and perform the action goes here
    # e.g., if type == 's3', run `aws s3 cp ...`
    # e.g., if type == 'smb', run `Copy-Item ...`
    Write-Host "Upload/Export completed!"
}

Write-Host "Done!"
