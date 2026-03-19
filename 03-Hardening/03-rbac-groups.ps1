# =============================================================
# 03-rbac-groups.ps1
# Phase 3 - Hardening | Azure Secure Hybrid Infrastructure
# Creation of AD groups and RBAC structure by business unit
# =============================================================

$Domain    = "DC=pme150,DC=local"
$OUBase    = "OU=Synced_Users,$Domain"

function Write-Step { param($msg) Write-Host "`n--- $msg ---"}
function Write-OK   { param($msg) Write-Host "[OK] $msg"}
function Write-Skip { param($msg) Write-Host "[SKIP] $msg already exists."}

function New-OUSafe {
    param($Name, $Path)
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path
        Write-OK "OU $Name created."
    } else { Write-Skip "OU $Name" }
}

function New-GroupSafe {
    param($Name, $Path, $Description)
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Name -GroupScope Global -GroupCategory Security `
                    -Path $Path -Description $Description
        Write-OK "Group $Name created."
    } else { Write-Skip "Group $Name" }
}

function New-UserSafe {
    param($Name, $UPN, $Path, $Password)
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$Name'" -ErrorAction SilentlyContinue)) {
        $SecPwd = ConvertTo-SecureString $Password -AsPlainText -Force
        New-ADUser -Name $Name -SamAccountName $Name `
                   -UserPrincipalName $UPN `
                   -Path $Path `
                   -AccountPassword $SecPwd `
                   -Enabled $true
        Write-OK "User $Name created."
    } else { Write-Skip "User $Name" }
}

# =============================================================
# 1. OU structure per businness unit
# =============================================================
Write-Step "OU Structure"

$Poles = @("IT","RH","Finance","Sales")
foreach ($Pole in $Poles) {
    New-OUSafe -Name "OU-$Pole" -Path $OUBase
}

# =============================================================
# 2. RBAC
# =============================================================
Write-Step "Security Groups"

$Groups = @(
    @{ Name="GRP-IT-Admins";      Path="OU=OU-IT,$OUBase";      Desc="Administrateurs IT — accès complet" },
    @{ Name="GRP-RH-Users";       Path="OU=OU-RH,$OUBase";      Desc="Personnel RH — données sensibles" },
    @{ Name="GRP-Finance-Users";  Path="OU=OU-Finance,$OUBase";  Desc="Pôle Finance — flux comptables" },
    @{ Name="GRP-Sales-Users";    Path="OU=OU-Sales,$OUBase";    Desc="Pôle Sales — flux commerciaux" },
    @{ Name="GRP-AllUsers";       Path=$OUBase;                  Desc="Tous les utilisateurs du domaine" }
)

foreach ($G in $Groups) {
    New-GroupSafe -Name $G.Name -Path $G.Path -Description $G.Desc
}

# =============================================================
# 3. User per hub
# =============================================================
Write-Step "Test Users"

$Users = @(
    @{ Name="user.it";      UPN="user.it@**********.onmicrosoft.com";      Path="OU=OU-IT,$OUBase";      Group="GRP-IT-Admins"     },
    @{ Name="user.rh";      UPN="user.rh@**********.onmicrosoft.comonmicrosoft.com";      Path="OU=OU-RH,$OUBase";      Group="GRP-RH-Users"      },
    @{ Name="user.finance"; UPN="user.finance@**********..onmicrosoft.com"; Path="OU=OU-Finance,$OUBase";  Group="GRP-Finance-Users" },
    @{ Name="user.sales";   UPN="user.sales@**********..onmicrosoft.com";   Path="OU=OU-Sales,$OUBase";   Group="GRP-Sales-Users"   }
)

$DefaultPassword = "Pme150!Secure#2025"

foreach ($U in $Users) {
    New-UserSafe -Name $U.Name -UPN $U.UPN -Path $U.Path -Password $DefaultPassword
    Add-ADGroupMember -Identity $U.Group -Members $U.Name -ErrorAction SilentlyContinue
    Add-ADGroupMember -Identity "GRP-AllUsers" -Members $U.Name -ErrorAction SilentlyContinue
    Write-OK "$($U.Name) added to $($U.Group)."
}

# =============================================================
# 4. Final check
# =============================================================
Write-Step "Validation"

Write-Host "`nGroupes AD :"
Get-ADGroup -Filter * -SearchBase $OUBase | Select-Object Name, GroupScope | Format-Table -AutoSize

Write-Host "`nUtilisateurs par OU :"
foreach ($Pole in $Poles) {
    Write-Host "`n  [$Pole]"
    Get-ADUser -Filter * -SearchBase "OU=OU-$Pole,$OUBase" | Select-Object Name, Enabled | Format-Table -AutoSize
}
