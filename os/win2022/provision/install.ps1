# ==============================================================================
# Script: install.ps1
# Description: Executes main application scaling, system hardening, and patching.
# ==============================================================================

function Show-ComponentStatus {
    Write-Output "--- Application & Patch Status ---"
    Get-Service -Name sshd, wuauserv, DiagTrack, dmwappushservice -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
    Get-NetFirewallRule -Name sshd, FPS-ICMP4-ERQ-In, FPS-ICMP6-ERQ-In -ErrorAction SilentlyContinue | Format-Table Name, Enabled, Action -AutoSize
    Get-NetFirewallRule -DisplayGroup "Remote Event Log Management", "Remote Service Management", "Remote Desktop" -ErrorAction SilentlyContinue | Format-Table DisplayGroup, Enabled, Action -AutoSize
    Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue | Format-Table Name, State -AutoSize
    
    Write-Output "[Key Registry Settings]"
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -ErrorAction SilentlyContinue | Select-Object PSChildName, AUOptions | Format-Table -AutoSize
    Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue | Select-Object PSChildName, fDenyTSConnections | Format-Table -AutoSize
    Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue | Select-Object PSChildName, AllowTelemetry | Format-Table -AutoSize

    Write-Output "----------------------------------"
    Write-Output "[Windows Admin Center]"
    Get-Service -Name ServerManagementGateway -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
    
    Write-Output "[Recent Windows Hotfixes]"
    Get-HotFix | Select-Object HotFixID, Description, InstalledBy | Format-Table -AutoSize
    Write-Output "----------------------------------"
}

Write-Output "=== STATUS BEFORE APPLY ==="
Show-ComponentStatus

Write-Output "=== APPLYING CONFIGURATIONS ==="

# ------------------------------------------------------------------------------
# 1. Silence Telemetry & Interactive Console Wizards (Server Manager / SConfig)
# ------------------------------------------------------------------------------
Write-Host "Disabling Server Manager and SConfig..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Force

if (Get-Command Set-SConfig -ErrorAction SilentlyContinue) {
    Set-SConfig -AutoLaunch $False
} else {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "SConfig" -Value "" -Force
}

# ------------------------------------------------------------------------------
# 2. Deploy Features on Demand (FoD)
# ------------------------------------------------------------------------------
Write-Host "Finding Features on Demand (FoD) ISO..."
$fodDrive = (Get-Volume).Where({ $_.DriveType -eq 'CD-ROM' -and (Test-Path "$($_.DriveLetter):\LanguagesAndOptionalFeatures\OpenSSH-Server-Package~31bf3856ad364e35~amd64~~.cab") })

if ($fodDrive) {
    $driveLetter = $fodDrive.DriveLetter
    Write-Host "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -Source "${driveLetter}:\LanguagesAndOptionalFeatures"
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    
    if (!(Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    }
} else {
    Write-Host "Features on Demand ISO not found on any CD-ROM!"
}

# ------------------------------------------------------------------------------
# 3. System Optimizations & Standard Security Profiles 
# ------------------------------------------------------------------------------
Write-Host "Applying System Optimizations and Security Profiles..."

Write-Host " -> Enabling Remote Management rules..."
Configure-SMRemoting.exe -Enable | Out-Null
Enable-NetFirewallRule -DisplayGroup "Remote Event Log Management" -ErrorAction SilentlyContinue
Enable-NetFirewallRule -DisplayGroup "Remote Service Management" -ErrorAction SilentlyContinue

Write-Host " -> Enabling ICMPv4/v6 Ping Response..."
Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" -ErrorAction SilentlyContinue
Enable-NetFirewallRule -Name "FPS-ICMP6-ERQ-In" -ErrorAction SilentlyContinue

Write-Host " -> Configuring Windows Update to Manual..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 2 -Force -ErrorAction SilentlyContinue
Set-Service wuauserv -StartupType Manual -ErrorAction SilentlyContinue

Write-Host " -> Enabling Secured Remote Desktop (RDP with NLA)..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1 -Force
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

Write-Host " -> Disabling OS Telemetry..."
if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service -Name dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 4. Install Custom ISO Payload (Windows Admin Center & Hotfixes)
# ------------------------------------------------------------------------------
Write-Host "Scanning all CD-ROMs for Windows Admin Center and Cumulative Updates..."
$cdroms = Get-Volume | Where-Object { $_.DriveType -eq 'CD-ROM' }

Write-Host 'Installing Windows Admin Center in Gateway Mode...'
$wacInstaller = $null
foreach ($disk in $cdroms) {
    $found = Get-ChildItem -Path "$($disk.DriveLetter):\" -Filter "WindowsAdminCenter*.exe" -ErrorAction SilentlyContinue
    if ($found) {
        $wacInstaller = $found.FullName
        break
    }
}

if ($wacInstaller) {
    $arguments = '/quiet SME_PORT=443 SSL_CERTIFICATE_OPTION=generate'
    Start-Process -FilePath $wacInstaller -ArgumentList $arguments -Wait -NoNewWindow
} else {
    Write-Warning "Windows Admin Center installer not found on any mounted ISO!"
}

Write-Host "Applying Cumulative Updates..."
$updates = @()
foreach ($disk in $cdroms) {
    $updates += Get-ChildItem -Path "$($disk.DriveLetter):\" -Filter "*.msu" -ErrorAction SilentlyContinue
}

if ($updates.Count -gt 0) {
    foreach ($update in $updates) {
        Write-Host "Installing $($update.Name) directly from iso..."
        Start-Process -FilePath 'wusa.exe' -ArgumentList "`"$($update.FullName)`" /quiet /norestart" -Wait -NoNewWindow
    }
} else {
    Write-Warning "No .msu cumulative updates found on any mounted ISO!"
}

Write-Output "=== STATUS AFTER APPLY ==="
Show-ComponentStatus
