# Azure Secure Hybrid Infrastructure : PME 50-150 collaborateurs


------------------------------------------------------------------------------------------

## 💻 Environnement de Développement
| Composant | Détails |
| :--- | :--- |
| **Machine** | MacBook Air (Puce M4) |
| **Mémoire** | 24 Go RAM (Optimisé pour Virtualisation/Containers) |
| **OS** | macOS |
| **Cible** | Microsoft Azure / Windows Server |

------------------------------------------------------------------------------------------


<br>
<br>
---


## **Vision & Contexte Métier**
Ce projet documente le déploiement automatisé d'une infrastructure IT souveraine pour une PME de 50 à 150 employés. L'enjeu est de fournir un environnement de travail sécurisé, hautement disponible et conforme aux exigences de Souveraineté des données.


<br>
<br>
---

## **Les Piliers du Projet**
* ***Souveraineté (Belgique Central) :*** Choix de la région belgiumcentral pour garantir une latence minimale et le respect du RGPD en gardant les données sur le sol national.
* ***Zero-GUI Policy :*** Déploiement 100% via Azure CLI et PowerShell pour une IaC, garantissant une reproductibilité parfaite sans erreur humaine.
* ***Hardening :*** Réduction drastique de la surface d'attaque via l'usage de Windows Server 2025 Core et une isolation stricte des flux administratifs.
* ***Architecture Réseau & Segmentation (VNet /23) :*** J’ai délibérément rejeté le standard /16 (65 536 IP) pour une approche "Zero Waste" adaptée à une PME de 100-150 employés.


| Ressource | Nom | Adresse / Région | Rôle |
| :--- | :--- | :--- | :--- |
| **Region** | `belgiumcentral` | Bruxelles | Souveraineté (RGPD) & Latence |
| **VNet** | `VNET-CORE` | 10.0.0.0/23 | Enveloppe PME (512 IP) |
| **Subnet Mgmt** | `Subnet-Management` | 10.0.0.0/27 | Administration (RDP lié IP dynamique) |
| **Subnet Id** | `Subnet-Identity` | 10.0.0.32/27 | Cœur Infra : 2 DC, AD DS, DNS & Entra Connect |
| **Subnet Data** | `Subnet-Data` | 10.0.1.0/24 | Zone Métier : RH, Finance, IT, Sales (150 collab.) |


<br>
<br>
---


## **Focus Stratégique :**
1. ***Identity (Le Cerveau) :*** Le choix du /27 permet d'accueillir deux contrôleurs de domaine pour la haute disponibilité et les mises à jour sans interruption de service.
2. ***Data (L'Efficience) :*** Un bloc /24 entier pour une lisibilité parfaite (10.0.1.x). L'isolation entre les services (RH, Finance...) est gérée logiquement pour protéger le trafic de données.


<br>
<br>
---


## **Roadmap de Déploiement (Sprint de 15 Jours  (cqfd les crédits azure étudiant))**

📂 **Phase 1 :** Network Foundation (✅)
* Provisionnement du VNet et des subnets segmentés.
* Sécurisation  via NSG (Network Security Groups).
  
📂 **Phase 2 :** Identity & Hybrid Management (🔄)
* Déploiement du premier contrôleur de domaine sur Windows Server 2025 Core.
* Configuration de l'AD DS, du DNS interne et préparation du lien Microsoft Entra ID.
  
📂 **Phase 3 :** System Hardening (⏳)
* Application de GPO de sécurité et durcissement des OS.
* Mise en place du RBAC (Role-Based Access Control).
