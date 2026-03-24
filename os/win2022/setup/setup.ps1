# ==============================================================================
# Script: setup.ps1
# Description: This bootstrap script runs during the Windows OOBE phase via 
# autounattend.xml's FirstLogonCommands block. It configures the foundational 
# OS components necessary so Packer can authenticate via WinRM effortlessly
# and seamlessly coordinate the rest of the build pipeline.
# ==============================================================================

Start-Transcript -Path "C:\setup_log.txt"

# ------------------------------------------------------------------------------
# Helper Function: Show-ComponentStatus
# Description: Provides robust debugging logs comparing pre/post states of WinRM 
# services, firewall rules, and OpenSSH Capability installations.
# ------------------------------------------------------------------------------
function Show-ComponentStatus {
    Write-Output "--- Component Status ---"
    Get-Service -Name WinRM, sshd, wuauserv, DiagTrack, dmwappushservice -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
    Get-NetFirewallRule -Name WinRM_HTTP, sshd, FPS-ICMP4-ERQ-In, FPS-ICMP6-ERQ-In -ErrorAction SilentlyContinue | Format-Table Name, Enabled, Action -AutoSize
    Get-NetFirewallRule -DisplayGroup "Remote Event Log Management", "Remote Service Management", "Remote Desktop" -ErrorAction SilentlyContinue | Format-Table DisplayGroup, Enabled, Action -AutoSize
    Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue | Format-Table Name, State -AutoSize
    
    Write-Output "[Key Registry Settings]"
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -ErrorAction SilentlyContinue | Select-Object PSChildName, AUOptions | Format-Table -AutoSize
    Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue | Select-Object PSChildName, fDenyTSConnections | Format-Table -AutoSize
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue | Select-Object PSChildName, AllowTelemetry | Format-Table -AutoSize
    Write-Output "------------------------"
}

Write-Output "=== STATUS BEFORE APPLY ==="
Show-ComponentStatus

Write-Output "=== APPLYING CONFIGURATIONS ==="

# ------------------------------------------------------------------------------
# 1. Enable Packer Communicator: Configure WinRM Service
# By default, WinRM rejects simple connections and encrypts traffic. For an 
# airgapped hypervisor builder, we deliberately Enable PSRemoting blindly, and 
# drop basic connection protections so Packer can log in and begin scripts.
# ------------------------------------------------------------------------------
Write-Host "Configuring WinRM..."
Enable-PSRemoting -Force -SkipNetworkProfileCheck
New-NetFirewallRule -Name "WinRM_HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985
Set-Item -Path WSMan:\Localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\Localhost\Service\AllowUnencrypted -Value $true
Set-Service WinRM -StartupType Automatic
Restart-Service WinRM

# ------------------------------------------------------------------------------
# 2. Deploy Extras: Windows OpenSSH Server Payload via FoD ISO
# Windows Server Features on Demand ISO must be dynamically scanned and mounted.
# Once matched via signature file (.cab), we inject OpenSSH globally.
# ------------------------------------------------------------------------------
Write-Host "Finding Features on Demand (FoD) ISO..."
$fodDrive = (Get-Volume).Where({ $_.DriveType -eq 'CD-ROM' -and (Test-Path "$($_.DriveLetter):\LanguagesAndOptionalFeatures\OpenSSH-Server-Package~31bf3856ad364e35~amd64~~.cab") })

if ($fodDrive) {
    $driveLetter = $fodDrive.DriveLetter
    Write-Host "FoD ISO found on ${driveLetter}:"
    Write-Host "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -Source "${driveLetter}:\LanguagesAndOptionalFeatures"
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    
    if (!(Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    }
    Write-Host "OpenSSH Server installed and started."
} else {
    Write-Host "Features on Demand ISO not found on any CD-ROM!"
}

# ------------------------------------------------------------------------------
# 3. Virtualization Integrations: VirtIO Guest Networking & QEMU Engine
# We iteratively seek the Red Hat VirtIO installation ISO on all optics drives.
# The core network drivers and PCI guest integrations are silently deployed.
# ------------------------------------------------------------------------------
Write-Host "Finding VirtIO ISO..."
$virtioDrive = (Get-Volume).Where({ $_.DriveType -eq 'CD-ROM' -and (Test-Path "$($_.DriveLetter):\virtio-win-gt-x64.msi") })

if ($virtioDrive) {
    $vDriveLetter = $virtioDrive.DriveLetter
    Write-Host "VirtIO ISO found on ${vDriveLetter}:"
    $msiPath = "${vDriveLetter}:\virtio-win-gt-x64.msi"
    
    Write-Host "Installing VirtIO Guest Tools from MSI..."
    # Execute the Microsoft Installer silently targeting machine root.
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
    Write-Host "VirtIO Guest Tools installed."
} else {
    Write-Host "VirtIO MSI not found on any CD-ROM!"
}

# ------------------------------------------------------------------------------
# 4. Silence Telemetry & Interactive Console Wizards
# Blocks native Windows Server Manager and SConfig from seizing control of the 
# host GUI during the boot sequence—greatly optimizing continuous integration.
# ------------------------------------------------------------------------------
Write-Host "Disabling Server Manager and SConfig..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Force

if (Get-Command Set-SConfig -ErrorAction SilentlyContinue) {
    # Exclusive to Windows Server 2022 onwards
    Set-SConfig -AutoLaunch $False
} else {
    # Fallback to older legacy Registry block overrides
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SConfig" -Value "" -Force
}

# ------------------------------------------------------------------------------
# 5. System Optimizations & Standard Security Profiles 
# Applies the user-requested OS hardening and accessibility defaults.
# ------------------------------------------------------------------------------
Write-Host "Applying System Optimizations and Security Profiles..."

# 5.1 Enable Remote Management (MMC, Event Viewer, Server Manager)
Write-Host " -> Enabling Remote Management rules..."
Configure-SMRemoting.exe -Enable | Out-Null
Enable-NetFirewallRule -DisplayGroup "Remote Event Log Management" -ErrorAction SilentlyContinue
Enable-NetFirewallRule -DisplayGroup "Remote Service Management" -ErrorAction SilentlyContinue

# 5.2 Enable Server Response to Ping (ICMP Echo Request)
Write-Host " -> Enabling ICMPv4/v6 Ping Response..."
Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" -ErrorAction SilentlyContinue
Enable-NetFirewallRule -Name "FPS-ICMP6-ERQ-In" -ErrorAction SilentlyContinue

# 5.3 Update Setting to Manual (Prevent random Windows Update restarts during uptime)
Write-Host " -> Configuring Windows Update to Manual..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 2 -Force -ErrorAction SilentlyContinue
Set-Service wuauserv -StartupType Manual -ErrorAction SilentlyContinue

# 5.4 Enable Remote Desktop (RDP) with Secured Network Level Authentication (NLA)
Write-Host " -> Enabling Secured Remote Desktop (RDP with NLA)..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

# 5.5 Disable Telemetry and Data Collection Services
Write-Host " -> Disabling OS Telemetry..."
if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service -Name dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue

Write-Output "=== STATUS AFTER APPLY ==="
Show-ComponentStatus

Write-Host "Setup complete! Awaiting WinRM Handshake..."
Start-Sleep -Seconds 5
Stop-Transcript
