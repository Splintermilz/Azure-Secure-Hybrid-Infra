# README — 02-Identity

---

## 1. Description & Objectifs

Cette étape constitue **le cœur de l'identité du réseau hybride**. Elle comprend le déploiement d'un contrôleur de domaine (DC) sous **Windows Server 2025 Core**, la promotion Active Directory, la configuration DNS, et la préparation du socle pour la synchronisation avec **Microsoft Entra ID**.

Deux priorités ont guidé chaque décision :

- **Zero-Trust** : aucune exposition publique, accès via Jumpbox uniquement, aucune IP publique assignée.
- **Automatisation** : déploiement 100% scriptable et idempotent (Infrastructure as Code).

---

## 2. Architecture & Stratégie

| Paramètre | Configuration | Pourquoi ? |
|---|---|---|
| Nom | `SRV-AD-01` | Standard de nommage Identity |
| Image | Windows Server 2025 Azure Edition Core | Support du Hotpatching — réduction de la surface d'attaque sans redémarrage |
| Réseau | `VNET-CORE / Subnet-Identity` (`10.0.0.32/27`) | Segmentation réseau stricte, HA-Ready (2 DC possibles) |
| IP Publique | Aucune | Isolation totale d'Internet — prévention des scans |
| Stockage | `StandardSSD_LRS` | Équilibre performance / coût |
| Localisation | `BelgiumCentral` | Souveraineté des données (RGPD) + cohérence avec le reste du VNet |

**Arbitrage Technique — HA-Ready Design** : Bien que l'infrastructure repose sur un nœud unique, le `Subnet-Identity` (`/27`) est pré-dimensionné pour accueillir un second DC (Haute Disponibilité).

**Héritage DNS** : `SRV-AD-01` (`10.0.0.36`) est désigné comme serveur DNS de référence pour l'ensemble des subnets métier. Le VNet a été mis à jour pour pointer vers cette IP plutôt que vers les résolveurs Azure par défaut, garantissant une résolution de noms native et transparente au domaine `pme150.local`.

```bash
az network vnet update \
  --resource-group "RG-LAB-HYBRID-INFRA" \
  --name "VNET-CORE" \
  --dns-servers "10.0.0.36"
```

> **Pourquoi ?** Cela force Azure à distribuer l'IP du contrôleur de domaine à toutes les interfaces réseau du VNet via DHCP. Toutes les nouvelles machines rejoindront instantanément le domaine `pme150.local` sans configuration manuelle.

---

## 3. Automatisation — `02-deploy-identity-vm.sh`

Le script de déploiement a été conçu pour être **idempotent** : il peut être exécuté plusieurs fois sans créer de doublons ni générer d'erreurs.

**Points clés du script :**

- **Gestion des secrets** : Récupération dynamique des variables `$VM_ADMIN` et `$VM_PASS` via un fichier `.env` sécurisé — jamais stockées en clair dans le script.
- **Idempotence** (`CHECK_VM`) : Vérification via `--query "[?name=='$VM_NAME'].name"` si la VM existe déjà avant toute tentative de création.
- **Garde-fous** (`trap`) : Codes de sortie (`if [ $? -eq 0 ]`) pour intercepter tout échec et stopper le script immédiatement, évitant un déploiement partiel silencieux.
- **Naming Convention** : Préfixes clairs (`SRV-`, `NSG-`) pour une maintenance facilitée, norme indispensable en entreprise.

---

## 4. Déploiement AD DS — Injection de Secrets

La promotion du domaine est orchestrée depuis le Mac via **Azure CLI**, sans jamais stocker de mot de passe en clair dans les scripts versionnés.

**Procédure :**

```bash
# 1. Charger les variables secrètes depuis le .env local
cd 02-Identity
source ../.env

# 2. Invoquer le script PowerShell sur la VM via l'agent Azure
az vm run-command invoke \
  --resource-group "RG-LAB-HYBRID-INFRA" \
  --name "SRV-AD-01" \
  --command-id "RunPowerShellScript" \
  --scripts @02-promote-ad.ps1 \
  --parameters "passwd=$VM_PASS"
```

> **Pourquoi cette méthode ?**
> - **Zéro Trace** : Le script `.ps1` sur GitHub reste générique et réutilisable — aucun secret committé.
> - **Isolation** : La VM n'a pas besoin d'accès direct au fichier `.env` ni à Internet pour recevoir sa configuration. Le secret transite uniquement en mémoire via l'agent Azure.

---

## 5. Sécurité — NSG `SRV-AD-01NSG`

Le groupe de sécurité réseau est configuré pour restreindre les flux au strict nécessaire.

| Priorité | Règle | Port | Action |
|---|---|---|---|
| 1000 | RDP (interne VNet uniquement) | 3389 TCP | Allow |
| 65000 | AllowVnetInBound | * | Allow |
| 65001 | AllowAzureLoadBalancer | * | Allow |
| 65500 | DenyAllInBound | * | Deny |

> **Note** : Le RDP (port 3389) est uniquement autorisé depuis l'intérieur du VNet, via la Jumpbox. Aucune exposition directe sur Internet. En production, cette configuration serait complétée par un VPN Point-to-Site ou Azure Bastion afin de supprimer totalement l'exposition du port RDP.

---

## 6. Connexion à SRV-AD-01

`SRV-AD-01` étant une machine **Core** (sans interface graphique), la connexion s'effectue en deux étapes :

**Étape 1** — RDP sur la Jumpbox (`VM-JUMPBOX`) via **Windows APP** (anciennement Microsoft Remote Desktop).

**Étape 2** — Session PowerShell distante depuis la Jumpbox vers le DC :

```powershell
# Autoriser la connexion distante (à faire une seule fois)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.0.0.36" -Force

# Ouvrir la session
Enter-PSSession -ComputerName 10.0.0.36 -Credential (Get-Credential)
```

---

## 7. Audit & Validation de l'Infrastructure AD DS

Une fois le serveur promu, l'infrastructure a été auditée pour confirmer la stabilité des services avant de passer à la suite.

**Validation DNS** : Le service `dns` est en état `Running` — prérequis vital pour la résolution de noms du réseau.

**Validation AD** : La commande `Get-ADDomain` confirme la création de la forêt racine `pme150.local` avec le niveau fonctionnel `Windows2016Domain`.

```powershell
# Audit depuis la session distante
az vm run-command invoke \
  --resource-group "RG-LAB-HYBRID-INFRA" \
  --name "SRV-AD-01" \
  --command-id "RunPowerShellScript" \
  --scripts "Get-Service dns; Get-ADDomain"
```

---

## 8. Préparation Microsoft Entra ID — Hybridité

Configuration du socle AD pour la future synchronisation avec **Entra ID Connect**.

*Pourquoi ?* Sans suffixe UPN public, les identités locales (`user@pme150.local`) ne peuvent pas être mappées vers des identités Cloud (`user@domaine.com`). Cette étape est indispensable avant toute synchronisation hybride.

```powershell
# 1. Ajout du suffixe UPN
$UserDomain = "**********.onmicrosoft.com"
Set-ADForest -Identity "pme150.local" -UPNSuffixes @{Add=$UserDomain}

# 2. Création de l'OU de synchronisation
# Bonne pratique : on ne synchronise jamais tout l'AD, seulement une OU dédiée
New-ADOrganizationalUnit -Name "Synced_Users" -Path "DC=pme150,DC=local"

# 3. Création d'un utilisateur de test
$Password = ConvertTo-SecureString "*******" -AsPlainText -Force
New-ADUser -Name "Admin Hybrid" `
           -UserPrincipalName "admin@$UserDomain" `
           -Path "OU=Synced_Users,DC=pme150,DC=local" `
           -AccountPassword $Password `
           -Enabled $true

# 4. Vérification
Get-ADForest | Select-Object -ExpandProperty UPNSuffixes
# Résultat attendu : **********.onmicrosoft.com
```

---

## ⚠️ Journal des complications & Arbitrages (Post-Mortem)

### 1. Indisponibilité des ressources — `SkuNotAvailable`

- **Problème** : La taille `Standard_B2s` n'était plus disponible en stock dans la région `BelgiumCentral`.
- **Résolution** : Passage sur `Standard_D2s_v3`, plus robuste et disponible, garantissant la continuité du projet.

### 2. Dilemme Auto-Shutdown — FinOps vs Souveraineté

- **Problème** : Le service `Microsoft.DevTestLab/schedules` (nécessaire pour l'auto-shutdown) n'est pas activable sur la zone `BelgiumCentral`.
- **Options évaluées** :
  - **Option A** : Déplacer la VM en `francecentral` → gain de l'auto-shutdown, perte de la souveraineté des données.
  - **Option B** : Rester en `belgiumcentral` → conservation de la souveraineté, arrêt manuel de la VM.
- **Décision** : **Option B — Souveraineté prioritaire.** La fonction auto-shutdown a été retirée du script. L'arrêt de la VM est géré manuellement pendant la phase de développement pour limiter la facturation.

### 3. Adressage IP des contrôleurs de domaine — DHCP vs Statique

- **Choix technique** : Allocation dynamique via DHCP Azure pour garantir un déploiement "Zero-Touch" sans conflit d'adressage.
- **Conscience des risques** : En production réelle, un contrôleur de domaine **doit** disposer d'une IP statique (réservée au niveau de la NIC Azure) afin de prévenir toute rupture de la chaîne DNS et de la réplication NTDS en cas de maintenance.

---

## ✅ État d'avancement — Bilan final Étape 2

| Composant | État | Validation |
|---|---|---|
| `SRV-AD-01` | ✅ OPÉRATIONNEL | IP privée `10.0.0.36` |
| Active Directory | ✅ OPÉRATIONNEL | Forêt `pme150.local` confirmée |
| DNS Interne | ✅ ACTIF | Service `dns` en `Running` |
| NSG | ✅ CONFIGURÉ | `SRV-AD-01NSG` opérationnel |
| Jumpbox → AD | ✅ VALIDÉ | Session PSSession établie |
| Suffixe UPN | ✅ AJOUTÉ | `**********.onmicrosoft.com` |
| OU Synced_Users | ✅ CRÉÉE | Prête pour Entra ID Connect |
| VNet DNS | ✅ MIS À JOUR | Pointé sur `10.0.0.36` |
| Entra ID Connect | ⏳ À VENIR | Installation — Phase suivante |
