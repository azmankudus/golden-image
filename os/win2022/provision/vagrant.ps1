# ==============================================================================
# Script: vagrant.ps1
# Description: Vagrant PKI binding mapped securely across target configurations.
# ==============================================================================

Write-Host "Bootstrapping Vagrant SSH Keys natively..."

# Bypass basic WinRM settings allowing headless Vagrant mapping natively
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Inject Vagrant SSH Keys
Write-Host "Downloading HashiCorp Insecure RSA Public Key..."
$keyDir = "C:\ProgramData\ssh"
if (-Not (Test-Path $keyDir)) {
    New-Item -ItemType Directory -Force -Path $keyDir | Out-Null
}

$pubKeyPath = "$keyDir\administrators_authorized_keys"
$url = "https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $pubKeyPath -UseBasicParsing

# Tighten the File ACL securely locking strictly Administrator operations
$acl = Get-Acl $pubKeyPath
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
Set-Acl $pubKeyPath $acl

Write-Host "Vagrant SSH architecture authenticated globally."
