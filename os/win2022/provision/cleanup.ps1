# ==============================================================================
# Script: cleanup.ps1
# Description: Purges the temporary file staging ground (C:\Temp) to ensure 
# the exported golden image remains compact and secure. Additionally 
# executes disk optimizations and TRIM commands natively to shrink the 
# sparse .qcow2 hard drive artifact perfectly.
# ==============================================================================

Write-Host "Cleaning up staging artifacts..."
Remove-Item -Path C:\Temp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Consolidating free space and sending TRIM commands to host..."
# -ReTrim cascades down to qemu 'disk_discard = "unmap"' to instantly punch holes 
# and shrink the hypervisor snapshot. -Defrag natively consolidates filesystem blocks.
Optimize-Volume -DriveLetter C -ReTrim -Defrag -Verbose
