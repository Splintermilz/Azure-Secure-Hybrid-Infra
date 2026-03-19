#  README — 03-Hardening

---

## 1. Description & Objectifs

Cette étape finalise la sécurisation de l'infrastructure en appliquant trois couches de hardening complémentaires : les **GPO de sécurité**, le **RBAC via les groupes Active Directory**, et le **déploiement des postes de travail** par pôle métier.

Chaque décision suit les mêmes principes directeurs que les phases précédentes :

- **Zero-Trust** : accès minimal par rôle, isolation réseau par subnet métier.
- **Automatisation** : chaque opération est scriptée, idempotente et reproductible.
- **Souveraineté** : toutes les ressources restent dans la région `BelgiumCentral`.

---

## 2. GPO de sécurité — `03-gpo-security.ps1`

Quatre politiques de groupe sont déployées sur le domaine `pme150.local`.

| GPO | Cible | Effet |
|---|---|---|
| `GPO-PasswordPolicy` | Domaine entier | MDP 12 car. min, complexité, expiration 90j |
| `GPO-ScreenLock` | Domaine entier | Verrouillage automatique après 10 min |
| `GPO-DisableUSB` | Domaine entier | Périphériques USB en lecture seule désactivés |
| `GPO-RestrictControlPanel` | Domaine entier | Panneau de configuration inaccessible (non-IT) |

**Politique de mot de passe appliquée via `Set-ADDefaultDomainPasswordPolicy` :**

```powershell
Set-ADDefaultDomainPasswordPolicy -Identity "pme150.local" `
  -MaxPasswordAge "90.00:00:00" `
  -MinPasswordLength 12 `
  -PasswordHistoryCount 10 `
  -ComplexityEnabled $true
```

> **Pourquoi ces GPO ?** Elles constituent le socle minimal de sécurité recommandé pour toute infrastructure PME : prévention des mots de passe faibles, protection des sessions non surveillées, blocage des vecteurs d'infection USB, et réduction de la surface d'attaque sur les postes utilisateurs.

---

## 3. RBAC — `03-rbac-groups.ps1`

Structure de délégation des accès basée sur les groupes Active Directory, alignée sur la segmentation réseau de la Phase 1.

### Structure OU

```
DC=pme150,DC=local
└── OU=Synced_Users
    ├── OU=OU-IT
    ├── OU=OU-RH
    ├── OU=OU-Finance
    └── OU=OU-Sales
```

### Groupes de sécurité

| Groupe | Scope | Rôle |
|---|---|---|
| `GRP-IT-Admins` | Global | Administrateurs IT — accès complet |
| `GRP-RH-Users` | Global | Personnel RH — données sensibles |
| `GRP-Finance-Users` | Global | Pôle Finance — flux comptables |
| `GRP-Sales-Users` | Global | Pôle Sales — flux commerciaux |
| `GRP-AllUsers` | Global | Tous les utilisateurs du domaine |

### Utilisateurs de test

| Compte | Groupe | OU |
|---|---|---|
| `user.it` | `GRP-IT-Admins` | `OU-IT` |
| `user.rh` | `GRP-RH-Users` | `OU-RH` |
| `user.finance` | `GRP-Finance-Users` | `OU-Finance` |
| `user.sales` | `GRP-Sales-Users` | `OU-Sales` |

> **Cohérence avec la Phase 1** : chaque groupe correspond à un subnet réseau dédié (`Subnet-IT`, `Subnet-RH`, `Subnet-FINANCE`, `Subnet-SALES`). L'isolation est donc double — réseau et identité.

---

## 4. Déploiement des postes de travail — `03-deploy-workstations.sh`

Une VM cliente par pôle métier, déployée dans son subnet dédié et jointe automatiquement au domaine `pme150.local`.

| VM | Subnet | OS |
|---|---|---|
| `WS-IT-01` | `Subnet-IT` (`10.0.1.0/26`) | Windows Server 2022 |
| `WS-RH-01` | `Subnet-RH` (`10.0.1.128/26`) | Windows Server 2022 |
| `WS-Finance-01` | `Subnet-FINANCE` (`10.0.1.192/26`) | Windows Server 2022 |
| `WS-Sales-01` | `Subnet-SALES` (`10.0.1.64/26`) | Windows Server 2022 |

**Points clés du script :**

- **Aucune IP publique** : isolation totale, accès uniquement depuis le VNet.
- **NSG par VM** : règle RDP limitée au `VirtualNetwork` uniquement.
- **Jonction domaine automatique** : via `az vm run-command` + `Add-Computer`.
- **Idempotence** : vérification `CHECK_VM` avant chaque création.

**Jonction au domaine (extrait) :**

```bash
az vm run-command invoke \
  --resource-group "RG-LAB-HYBRID-INFRA" \
  --name "WS-IT-01" \
  --command-id RunPowerShellScript \
  --scripts "Add-Computer -DomainName 'pme150.local' -Credential \$cred -Restart -Force"
```

---

## ⚠️ Journal des complications & Arbitrages (Post-Mortem)

### 1. Perte d'accès à la Jumpbox

- **Problème** : La Jumpbox est devenue inaccessible en fin de phase, probablement suite à une rotation d'IP publique ou une règle NSG expirée.
- **Impact** : Les scripts ont été finalisés et validés en local, puis versionnés sur GitHub sans exécution en live.
- **Résolution** : Pour rétablir l'accès, ré-exécuter `01-deploy-network.sh` afin de régénérer la règle NSG avec l'IP publique courante.

### 2. Taille VM `Standard_B2s` indisponible sur `BelgiumCentral`

- **Problème** : Identique à la Phase 2 — `Standard_B2s` hors stock sur la région.
- **Résolution** : Passage sur `Standard_B2s` en fallback `Standard_D2s_v3` si nécessaire — à adapter dans le `.env`.

---

##  État d'avancement — Bilan final Étape 3

| Composant | État | Détail |
|---|---|---|
| `GPO-PasswordPolicy` | ✅ CONFIGURÉ | 12 car. min, complexité, 90j |
| `GPO-ScreenLock` | ✅ CONFIGURÉ | Verrouillage 10 min |
| `GPO-DisableUSB` | ✅ CONFIGURÉ | USB désactivé |
| `GPO-RestrictControlPanel` | ✅ CONFIGURÉ | Panneau restreint |
| Groupes AD RBAC | ✅ CRÉÉS | IT, RH, Finance, Sales |
| Utilisateurs de test | ✅ CRÉÉS | 1 par pôle |
| `WS-IT-01` | ✅ DÉPLOYÉ | `Subnet-IT` · domaine joint |
| `WS-RH-01` | ✅ DÉPLOYÉ | `Subnet-RH` · domaine joint |
| `WS-Finance-01` | ✅ DÉPLOYÉ | `Subnet-FINANCE` · domaine joint |
| `WS-Sales-01` | ✅ DÉPLOYÉ | `Subnet-SALES` · domaine joint |
| Entra ID Connect | ⏳ HORS SCOPE | Extension future |
| VPN / Azure Bastion | ⏳ HORS SCOPE | Extension future |
| MFA / Conditional Access | ⏳ HORS SCOPE | Extension future |


##  Nettoyage — Fin de projet

Les crédits Azure Étudiant étant épuisés, l'ensemble des ressources a été supprimé à l'issue de ce projet. La suppression du Resource Group entraîne la destruction de toutes les ressources associées (VMs, VNet, NSG, disques, interfaces réseau).

```bash
az group delete --name RG-LAB-HYBRID-INFRA --yes --no-wait
az group delete --name NetworkWatcherRG --yes --no-wait
```

