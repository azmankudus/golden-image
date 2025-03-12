# Change hostname to 'winserver'
Rename-Computer -NewName "winserver" -Force

# Enable Remote Management (WinRM)
Enable-PSRemoting -Force
Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=Yes

# Enable ICMP (Ping)
netsh advfirewall firewall add rule name="Allow ICMPv4-In" protocol=icmpv4 dir=in action=allow

# Set Windows Update to Manual
Set-Service -Name wuauserv -StartupType Manual

# Disable Telemetry (Connected User Experiences and Telemetry)
Stop-Service -Name DiagTrack -Force
Set-Service -Name DiagTrack -StartupType Disabled
Stop-Service -Name dmwappushservice -Force
Set-Service -Name dmwappushservice -StartupType Disabled
reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

@"
version   = $env:PACKER_BUILD_VERSION
timestamp = $(Get-Date)
"@ | Set-Content C:\Windows\System32\drivers\etc\packer.build

Get-Content C:\Windows\System32\drivers\etc\packer.build