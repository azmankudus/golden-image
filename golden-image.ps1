param(
    [switch]$List,
    [string]$Os,
    [string]$Virt,
    [int]$Cpu,
    [int]$Memory,
    [int]$DiskSize,
    [string]$DiskLayout,
    [string]$Mode = "base",
    [string]$SetupMode,
    [string]$RemoteConfig,
    [string]$UploadConfig,
    [string]$Name,
    [string]$NetDevice,
    [string]$Iso,
    [string]$IsoChecksum,
    [string]$ToolsIso,
    [switch]$Gui
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
        }
        else {
            Write-Host "Cached ISO found: $DestFile"
        }
        return $DestFile
    }
    elseif ($Uri -match "^smb://") {
        if (-not (Test-Path $DestFile)) {
            Write-Host "Downloading $Uri to $DestFile..."
            $SmbPath = $Uri -replace "^smb://", "\\" -replace "/", "\"
            Copy-Item -Path $SmbPath -Destination $DestFile
        }
        else {
            Write-Host "Cached ISO found: $DestFile"
        }
        return $DestFile
    }
    elseif ($Uri -match "^(http|https|ftp|ftps|sftp)://") {
        if (-not (Test-Path $DestFile)) {
            Write-Host "Downloading $Uri to $DestFile..."
            Invoke-WebRequest -Uri $Uri -OutFile $DestFile
        }
        else {
            Write-Host "Cached ISO found: $DestFile"
        }
        return $DestFile
    }
    elseif ($Uri -match "^file://") {
        $LocalPath = $Uri -replace "^file://", ""
        return $LocalPath
    }
    elseif ([System.IO.Path]::IsPathRooted($Uri)) {
        return $Uri
    }
    else {
        return (Resolve-Path $Uri).Path
    }
}


Write-Host "Building Golden Image for OS: $Os"
Write-Host "Virtualization: $Virt"
Write-Host "Mode: $Mode"

if (-not (Test-Path "output")) {
    if (Test-Path "/work/golden-image") {
        New-Item -ItemType Directory -Force -Path "/work/golden-image/output" | Out-Null
        New-Item -ItemType SymbolicLink -Path "output" -Target "/work/golden-image/output" | Out-Null
    }
    else {
        New-Item -ItemType Directory -Force -Path "output" | Out-Null
    }
}
$OutputDir = (Resolve-Path "output").Path + "\$Os-$Virt"

$PackerArgs = @()
$PackerArgs += "-var", "output_dir=$OutputDir"

if ($Gui) {
    $PackerArgs += "-var", "headless=false"
    Write-Host "GUI Mode: Enabled"
}

if ($SetupMode) {
    $PackerArgs += "-var", "setup_mode=$SetupMode"
    Write-Host "Setup Mode: $SetupMode"
    
    if ($Mode -eq "vagrant") {
        $PackerArgs += "-var", "floppy_image=../../floppy/${Os}-${SetupMode}-setup-vagrant.img"
    } else {
        $PackerArgs += "-var", "floppy_image=../../floppy/${Os}-${SetupMode}-setup-qemu.img"
    }
}

if ($Mode -eq "vagrant") {
    Write-Host "Output Mode: Vagrant Box Compile"
    $PackerArgs += "-var", "is_vagrant=true"
    $PackerArgs += "-var", "winrm_password=vagrant"
} else {
    Write-Host "Output Mode: Generic QEMU Artifact"
    $PackerArgs += "-except=qemu.vagrant-box"
}

if ($Name) {
    $PackerArgs += "-var", "vm_name=$Name"
    Write-Host "VM Name: $Name"
}

if ($NetDevice) {
    $PackerArgs += "-var", "net_device=$NetDevice"
    Write-Host "Net Device: $NetDevice"
}

if ($Cpu) {
    $PackerArgs += "-var", "cpus=$Cpu"
    Write-Host "Overrides CPU: $Cpu"
}

if ($Memory) {
    $PackerArgs += "-var", "memory=$Memory"
    Write-Host "Overrides Memory: $Memory"
}

if ($DiskSize) {
    $PackerArgs += "-var", "disk_size=$DiskSize"
    Write-Host "Overrides Disk Size: $DiskSize"
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
    if (-not $IsoChecksum) {
        $IsoChecksum = "none"
    }
}

if ($IsoChecksum) {
    $PackerArgs += "-var", "iso_checksum=$IsoChecksum"
}

if ($ToolsIso) {
    $ResolvedToolsIso = Resolve-Or-Fetch-Iso -Uri $ToolsIso -DestDir $IsoCacheDir
    Write-Host "Using Tools ISO: $ResolvedToolsIso"
    $PackerArgs += "-var", "tools_iso=$ResolvedToolsIso"
}

$VirtDir = "os\$Os\packer\$Virt"
if (-not (Test-Path $VirtDir)) {
    Write-Error "Virtualization platform '$Virt' is not implemented for OS '$Os'."
    exit 1
}

$PkrFiles = Get-ChildItem -Path $VirtDir -Filter "*.pkr.hcl" -ErrorAction SilentlyContinue
if (-not $PkrFiles) {
    Write-Error "No Packer templates found in $VirtDir"
    exit 1
}

Push-Location $VirtDir

# Set up logging
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ImageName = if ($Name) { $Name } else { "$Os-$Virt" }
$LogDir = (Resolve-Path "..\..\..\..").Path + "\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
}
$LogFile = "$LogDir\$Timestamp-$ImageName.log"

Write-Host "Logging output to: $LogFile"
Start-Transcript -Path $LogFile -Append -NoClobber | Out-Null

try {
    Write-Host "Initializing Packer plugins..."
    packer init .

    Write-Host "Running: packer build $PackerArgs ."
    packer build $PackerArgs .

    if ($UploadConfig) {
        Write-Host ""
        Write-Host "Post-Build: Executing upload/export sequence based on $UploadConfig..."
        Write-Host "Upload/Export completed!"
    }

    Write-Host "Done!"
} finally {
    Stop-Transcript | Out-Null
    Pop-Location
}
