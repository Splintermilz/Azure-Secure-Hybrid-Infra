
# # ===========================================================================
# SCRIPT: 02-promote-ad.ps1
# DESCRIPTION: Install the AD DS role and create the root forest "pme150.local"
# ARCHITECTURE: Windows Server 2025 Core (BelgiumCentral)
# # ===========================================================================
#
# 1. Set up .env dynamiccaly retrieve the VM_PASS variable
Param(
    [Parameter(Mandatory=$true)]
    [string]$passwd
)


# Check 4 idempotence (NTDS)
if (Get-Service ntds -ErrorAction SilentlyContinue) {
    Write-Host "Server is already DC // Skiping ..."
    exit 0
}

# Config Active Directory
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Config new forest :  PME150.local
Import-Module ADDSDeployment
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "pme150.local" `
    -DomainNetbiosName "PME150" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString -String $passwd -AsPlainText -Force)
