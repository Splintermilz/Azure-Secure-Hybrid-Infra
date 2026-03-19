# =============================================================
# 03-gpo-security.ps1
# Phase 3 - Hardening | Azure Secure Hybrid Infrastructure
# Déploiement des GPO de sécurité sur pme150.local
# Idempotent : vérifie l'existence avant création
# =============================================================

$Domain = "DC=pme150,DC=local"

function Write-Step { param($msg) Write-Host "`n--- $msg ---" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Skip { param($msg) Write-Host "[SKIP] $msg already exists." -ForegroundColor Yellow }

# =============================================================
# 1. Politique de mot de passe du domaine
# =============================================================
Write-Step "Password Policy"

Set-ADDefaultDomainPasswordPolicy -Identity "pme150.local" `
    -MaxPasswordAge     "90.00:00:00" `
    -MinPasswordAge     "1.00:00:00"  `
    -MinPasswordLength  12            `
    -PasswordHistoryCount 10          `
    -ComplexityEnabled  $true         `
    -ReversibleEncryptionEnabled $false

Write-OK "Domain password policy applied."

# =============================================================
# 2. GPO — Verrouillage de session (10 min)
# =============================================================
Write-Step "GPO-ScreenLock"

$GPO = Get-GPO -Name "GPO-ScreenLock" -ErrorAction SilentlyContinue
if (-not $GPO) {
    $GPO = New-GPO -Name "GPO-ScreenLock"
    New-GPLink -Name "GPO-ScreenLock" -Target $Domain | Out-Null
    Write-OK "GPO-ScreenLock created and linked."
} else { Write-Skip "GPO-ScreenLock" }

Set-GPRegistryValue -Name "GPO-ScreenLock" `
    -Key "HKCU\Control Panel\Desktop" `
    -ValueName "ScreenSaveTimeOut" -Type String -Value "600"
Set-GPRegistryValue -Name "GPO-ScreenLock" `
    -Key "HKCU\Control Panel\Desktop" `
    -ValueName "ScreenSaverIsSecure" -Type String -Value "1"
Set-GPRegistryValue -Name "GPO-ScreenLock" `
    -Key "HKCU\Control Panel\Desktop" `
    -ValueName "SCRNSAVE.EXE" -Type String -Value "scrnsave.scr"

# =============================================================
# 3. GPO — Désactivation des périphériques USB (Zero-Trust)
# =============================================================
Write-Step "GPO-DisableUSB"

$GPO = Get-GPO -Name "GPO-DisableUSB" -ErrorAction SilentlyContinue
if (-not $GPO) {
    $GPO = New-GPO -Name "GPO-DisableUSB"
    New-GPLink -Name "GPO-DisableUSB" -Target $Domain | Out-Null
    Write-OK "GPO-DisableUSB created and linked."
} else { Write-Skip "GPO-DisableUSB" }

Set-GPRegistryValue -Name "GPO-DisableUSB" `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" `
    -ValueName "Start" -Type DWord -Value 4

# =============================================================
# 4. GPO — Désactivation du panneau de configuration (non-IT)
# =============================================================
Write-Step "GPO-RestrictControlPanel"

$GPO = Get-GPO -Name "GPO-RestrictControlPanel" -ErrorAction SilentlyContinue
if (-not $GPO) {
    $GPO = New-GPO -Name "GPO-RestrictControlPanel"
    New-GPLink -Name "GPO-RestrictControlPanel" -Target $Domain | Out-Null
    Write-OK "GPO-RestrictControlPanel created and linked."
} else { Write-Skip "GPO-RestrictControlPanel" }

Set-GPRegistryValue -Name "GPO-RestrictControlPanel" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" -Type DWord -Value 1

# =============================================================
# 5. Vérification finale
# =============================================================
Write-Step "Validation"
Get-GPO -All | Select-Object DisplayName, GpoStatus | Format-Table -AutoSize
Get-ADDefaultDomainPasswordPolicy -Identity "pme150.local"
