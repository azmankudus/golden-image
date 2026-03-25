# ==============================================================================
# Script: setup.ps1
# Description: Minimal OS bootstrapper. Only enables Packer WinRM communicator 
# and VirtIO drivers. All other rules pushed to Packer provisioners natively.
# ==============================================================================

Start-Transcript -Path "C:\setup_log.txt"

function Show-ComponentStatus {
    Write-Output "--- Component Status ---"
    Get-Service -Name WinRM -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
    Get-NetFirewallRule -Name WinRM_HTTP -ErrorAction SilentlyContinue | Format-Table Name, Enabled, Action -AutoSize
    Write-Output "------------------------"
}

Write-Output "=== STATUS BEFORE APPLY ==="
Show-ComponentStatus

Write-Output "=== APPLYING CONFIGURATIONS ==="

# ------------------------------------------------------------------------------
# 1. Enable Packer Communicator: Configure WinRM Service
# ------------------------------------------------------------------------------
Write-Host "Configuring WinRM..."
Enable-PSRemoting -Force -SkipNetworkProfileCheck
New-NetFirewallRule -Name "WinRM_HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985
Set-Item -Path WSMan:\Localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\Localhost\Service\AllowUnencrypted -Value $true
Set-Service WinRM -StartupType Automatic
Restart-Service WinRM

# ------------------------------------------------------------------------------
# 2. Virtualization Integrations: VirtIO Guest Networking & QEMU Engine
# ------------------------------------------------------------------------------
Write-Host "Finding VirtIO ISO..."
$virtioDrive = (Get-Volume).Where({ $_.DriveType -eq 'CD-ROM' -and (Test-Path "$($_.DriveLetter):\virtio-win-gt-x64.msi") })

if ($virtioDrive) {
    $vDriveLetter = $virtioDrive.DriveLetter
    Write-Host "VirtIO ISO found on ${vDriveLetter}:"
    $msiPath = "${vDriveLetter}:\virtio-win-gt-x64.msi"
    
    Write-Host "Installing VirtIO Guest Tools from MSI..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
    Write-Host "VirtIO Guest Tools installed."
} else {
    Write-Host "VirtIO MSI not found on any CD-ROM!"
}

Write-Output "=== STATUS AFTER APPLY ==="
Show-ComponentStatus

Write-Host "Setup complete! Awaiting WinRM Handshake..."
Start-Sleep -Seconds 5
Stop-Transcript
