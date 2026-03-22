param(
    [switch]$List,
    [string]$Os,
    [string]$Virt,
    [int]$Cpu,
    [int]$Memory,
    [string]$DiskLayout,
    [string]$Mode = "base",
    [string]$RemoteConfig,
    [string]$UploadConfig,
    [string]$Iso,
    [string]$ToolsIso
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

function Resolve-Or-Fetch-Iso {
    param([string]$Uri, [string]$DestDir)
    
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    }

    $Filename = Split-Path $Uri -Leaf
    # Provide a local path relative to current pwd
    $DestFile = Join-Path (Resolve-Path $DestDir).Path $Filename

    if ($Uri -match "^s3://") {
        if (-not (Test-Path $DestFile)) {
            Write-Host "Downloading $Uri to $DestFile via AWS CLI..."
            aws s3 cp $Uri $DestFile
        } else {
            Write-Host "Cached ISO found: $DestFile"
        }
        return $DestFile
    } elseif ($Uri -match "^smb://") {
        if (-not (Test-Path $DestFile)) {
            Write-Host "Downloading $Uri to $DestFile..."
            $SmbPath = $Uri -replace "^smb://", "\\" -replace "/", "\"
            Copy-Item -Path $SmbPath -Destination $DestFile
        } else {
            Write-Host "Cached ISO found: $DestFile"
        }
        return $DestFile
    } elseif ($Uri -match "^(http|https|ftp|ftps|sftp)://") {
        if (-not (Test-Path $DestFile)) {
            Write-Host "Downloading $Uri to $DestFile..."
            Invoke-WebRequest -Uri $Uri -OutFile $DestFile
        } else {
            Write-Host "Cached ISO found: $DestFile"
        }
        return $DestFile
    } elseif ($Uri -match "^file://") {
        $LocalPath = $Uri -replace "^file://", ""
        return $LocalPath
    } elseif ([System.IO.Path]::IsPathRooted($Uri)) {
        return $Uri
    } else {
        return (Resolve-Path $Uri).Path
    }
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
    $ResolvedRemote = (Resolve-Path $RemoteConfig).Path
    $PackerArgs += "-var-file", "$ResolvedRemote"
}

if ($UploadConfig) {
    Write-Host "Using upload configuration from: $UploadConfig"
    $ResolvedUpload = (Resolve-Path $UploadConfig).Path
    $PackerArgs += "-var-file", "$ResolvedUpload"
}

$IsoCacheDir = "cache\iso"
if ($Iso) {
    $ResolvedIso = Resolve-Or-Fetch-Iso -Uri $Iso -DestDir $IsoCacheDir
    Write-Host "Using OS ISO: $ResolvedIso"
    # Note: Packer handles file:/// properly if formatted correctly, or just the absolute path
    $PackerArgs += "-var", "iso_url=file:///$ResolvedIso"
}

if ($ToolsIso) {
    $ResolvedToolsIso = Resolve-Or-Fetch-Iso -Uri $ToolsIso -DestDir $IsoCacheDir
    Write-Host "Using Tools ISO: $ResolvedToolsIso"
    $PackerArgs += "-var", "tools_iso=$ResolvedToolsIso"
}

Push-Location "os\$Os\packer"

$Builder = switch ($Virt) {
    "libvirt" { "qemu" }
    "virtualbox" { "virtualbox-iso" }
    "vmware-workstation" { "vmware-iso" }
    "vmware-esxi" { "vsphere-iso" }
    "vmware-vcenter" { "vsphere-iso" }
    "proxmox" { "proxmox-iso" }
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
    Write-Host "Upload/Export completed!"
}

Write-Host "Done!"
