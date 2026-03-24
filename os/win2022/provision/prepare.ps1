# ==============================================================================
# Script: prepare.ps1
# Description: Creates temporary directories for staging installation files.
# These directories hold Windows updates (kb) and auxiliary tools (extra).
# They are populated by Packer's `file` provisioner before the main install.
# ==============================================================================

Write-Host "Creating staging directories under C:\Temp..."
New-Item -ItemType Directory -Force -Path C:\Temp\update | Out-Null
New-Item -ItemType Directory -Force -Path C:\Temp\extra | Out-Null
