# ☁️  Azure Secure Hybrid Infrastructure — PME 50-150 collaborateurs

---

## 💻 Environnement de Développement

| Composant | Détails |
|-----------|---------|
| Machine | MacBook Air M4 |
| Mémoire | 24 Go RAM |
| OS | macOS |
| Cible | Microsoft Azure / Windows Server 2025 Core |

---

## Vision & Contexte Métier

Ce projet documente le déploiement automatisé d'une infrastructure IT souveraine pour une PME de 50 à 150 employés. L'enjeu est de fournir un environnement de travail sécurisé, évolutif et conforme aux exigences de **Souveraineté des données (RGPD)**.

---

## Les Piliers du Projet

- 🇧🇪 **Souveraineté (Belgium Central)** : Choix stratégique de la région `belgiumcentral` pour garantir une latence minimale et le maintien des données sur le sol national.
- ⌨️ **Zero-GUI Policy** : Déploiement 100% via Azure CLI et PowerShell (Infrastructure as Code), garantissant une reproductibilité parfaite et une piste d'audit claire.
- 🔒 **Hardening** : Réduction de la surface d'attaque via l'usage exclusif de Windows Server 2025 Core (sans interface graphique) et isolation stricte des flux.
- 🌐 **Architecture Réseau "Zero Waste" (VNet /23)** : Utilisation d'un bloc de 512 IP, offrant un équilibre idéal entre économie de ressources Cloud et capacité d'évolution réelle.

---

## Cartographie Réseau & Segmentation

| Ressource | Nom | CIDR | Rôle |
|-----------|-----|------|------|
| VNet | VNET-CORE | `10.0.0.0/23` | Enveloppe Globale (512 IP) |
| Subnet Mgmt | Subnet-Management | `10.0.0.0/27` | Administration (Accès restreint par IP dynamique) |
| Subnet Id | Subnet-Identity | `10.0.0.32/27` | Cœur Identity : Dimensionné pour HA (2 DC Ready) |
| Subnet IT | Subnet-IT | `10.0.1.0/26` | Zone dédiée aux administrateurs et outils IT |
| Subnet SALES | Subnet-SALES | `10.0.1.64/26` | Isolation des flux commerciaux |
| Subnet RH | Subnet-RH | `10.0.1.128/26` | Protection des données sensibles (Personnel) |
| Subnet FINANCE | Subnet-FINANCE | `10.0.1.192/26` | Zone critique (Flux comptables et bancaires) |

---

## Focus Stratégique

### 1. Identity (Le Cerveau) — *HA-Ready Design*

L'infrastructure repose actuellement sur un contrôleur de domaine principal (`SRV-AD-01`).

> **Arbitrage Technique** : Bien que le projet valide l'identité sur un nœud unique pour optimiser les ressources du Lab, le subnet Identity (`/27`) est pré-configuré pour accueillir un second DC (Haute Disponibilité) sans aucune modification d'adressage.

- **Services** : AD DS et DNS sont fusionnés pour une réplication native et une simplification de la résolution de noms interne.

### 2. Data & Workstations (L'Efficience) — *Micro-Segmentation*

Le bloc initial `10.0.1.0/24` a été refactorisé en **4 segments distincts (`/26`)**.

- 🛡️ **Sécurité Zero-Trust** : Chaque département est confiné dans son propre segment. Cela limite drastiquement la propagation latérale (*Lateral Movement*) en cas de compromission d'une station de travail.
- 🔗 **Héritage DNS** : Tous les subnets métiers pointent automatiquement vers l'IP `10.0.0.36` pour une intégration transparente au domaine.

---

## Roadmap de Déploiement — Sprint 15 jours

### 📂 Phase 1 : Network Foundation 

- Provisionnement du VNet et refactoring de la segmentation métier (`/26`).
- Sécurisation périmétrique via NSG (Network Security Groups) avec filtrage IP dynamique.

### 📂 Phase 2 : Identity & Hybrid Management 

- Déploiement de `SRV-AD-01` (Windows Server 2025 Core).
- Promotion AD DS, configuration DNS et préparation du socle pour Microsoft Entra ID.
- > *Design validé pour extension HA ultérieure.*

### 📂 Phase 3 : Workstations & Hardening 

- Déploiement des stations de travail par pôle métier.
- Application de GPO (Group Policy Objects) de sécurité.
- Mise en place du RBAC (Role-Based Access Control).

---

## Conclusion & Vision Long Terme

Ce projet démontre qu'une PME peut disposer d'un environnement Cloud **souverain** et **hautement sécurisé** sans surcoût inutile. En privilégiant l'automatisation et une segmentation réseau granulaire, l'infrastructure est prête pour l'industrialisation et l'hybridation avec **Microsoft Entra ID**.
