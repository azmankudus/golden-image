# ==============================================================================
# Script: install.ps1
# Description: Executes main application scaling operations and OS patching.
# Handles the silent deployment of Windows Admin Center and all cumulative 
# Windows Updates (.msu) transferred to the VM by Packer.
# ==============================================================================

function Show-ComponentStatus {
    Write-Output "--- Application & Patch Status ---"
    Write-Output "[Windows Admin Center]"
    Get-Service -Name ServerManagementGateway -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
    
    Write-Output "[Recent Windows Hotfixes]"
    # Scrapes the 5 most recently installed cumulative KBs to confirm packer execution
    Get-HotFix | Select-Object HotFixID, Description, InstalledBy | Format-Table -AutoSize
    Write-Output "----------------------------------"
}

Write-Output "=== STATUS BEFORE APPLY ==="
Show-ComponentStatus

Write-Output "=== APPLYING CONFIGURATIONS ==="

Write-Host 'Installing Windows Admin Center in Gateway Mode...'
# The WAC installer is staged in the extra directory
$wacInstaller = 'C:\Temp\extra\WindowsAdminCenter2511.exe'

if (Test-Path $wacInstaller) {
    # /quiet for silent run, SME_PORT sets the default Web UI port
    $arguments = '/quiet SME_PORT=443 SSL_CERTIFICATE_OPTION=generate'
    Start-Process -FilePath $wacInstaller -ArgumentList $arguments -Wait -NoNewWindow
    Write-Host 'Windows Admin Center installation completed.'
} else {
    Write-Warning "Windows Admin Center installer not found at $wacInstaller"
}

Write-Host 'Applying Cumulative Updates from C:\Temp\update...'
# Find all Microsoft Update Standalone Packages staged by Packer
$updates = Get-ChildItem -Path C:\Temp\update -Filter *.msu

foreach ($update in $updates) {
    Write-Host "Installing $($update.Name)..."
    # wusa.exe is the Windows Update Standalone Installer. We use /norestart 
    # to prevent abrupt termination of the Packer provisioning process.
    Start-Process -FilePath 'wusa.exe' -ArgumentList "`"$($update.FullName)`" /quiet /norestart" -Wait -NoNewWindow
}

Write-Output "=== STATUS AFTER APPLY ==="
Show-ComponentStatus
