# ==============================================================================
# SCRIPT: 02-promote-ad-secondary.ps1
# DESCRIPTION: Promotes SRV-AD-02 as an additional Domain Controller.
# WHY: High Availability for Identity and DNS services.
# HOW: Checks for AD DS role and Domain membership before execution.
# ==============================================================================
#
Write-Host "--------------------------------------------------" 
Write-Host "Starting High Availability Setup: SRV-AD-02" 
Write-Host "--------------------------------------------------" 

#--- Variable
$DomainName = "pme150.local"




# 1. Check if AD DS Role is already installed
# Why: Avoid unnecessary re-installation attempts.
if ((Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Write-Host "[OK] AD-Domain-Services role is already installed." 
} else {
    Write-Host "[..] Installing AD-Domain-Services role..." 
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    if ($?) { Write-Host "[OK] Role installed successfully."  }
}



# 2. Check if Server is already a Domain Controller
# Why: Essential for idempotence - do not promote if already a DC.
$SysInfo = Get-WmiObject Win32_ComputerSystem
if ($SysInfo.DomainRole -eq 4 -or $SysInfo.DomainRole -eq 5) {
    Write-Host "[SKIP] This server is already a Domain Controller for $DomainName."
    exit 0
}

# 3. Promotion to Additional Domain Controller
# How: Joining the existing forest pme150.local with replica parameters.
Write-Host "[..] Promoting to Additional Domain Controller (Replica)..."

try {
    Import-Module ADDSDeployment
    Install-ADDSDomainController `
        -NoGlobalCatalog:$false `
        -CreateDNSDelegation:$false `
        -Credential (Get-Credential) `
        -CriticalReplicationOnly:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainName $DomainName `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -ReplicationSourceDC "SRV-AD-01.$DomainName" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true
    
    Write-Host " Promotion successful. The server will now reboot." 
}
catch {
    Write-Error " Promotion failed. Please check network connectivity to SRV-AD-01 or credentials."
    exit 1
}
