# Azure Secure Hybrid Infrastructure : PME 50-150 collaborateurs


**Vision & Contexte Métier**
Ce projet documente le déploiement automatisé d'une infrastructure IT souveraine pour une PME de 50 à 150 employés. L'enjeu est de fournir un environnement de travail sécurisé, hautement disponible et conforme aux exigences de Souveraineté des données.


**Les Piliers du Projet**
* Souveraineté (Belgique Central) : Choix de la région belgiumcentral pour garantir une latence minimale et le respect du RGPD en gardant les données sur le sol national.
* Zero-GUI Policy : Déploiement 100% via Azure CLI et PowerShell pour une IaC, garantissant une reproductibilité parfaite sans erreur humaine.
* Hardening : Réduction drastique de la surface d'attaque via l'usage de Windows Server 2025 Core et une isolation stricte des flux administratifs.

Architecture Réseau & Segmentation (VNet /23)
J'ai opté pour une approche "Zero Waste" (512 IP), équilibre idéal entre économie de ressources et capacité d'évolution.



**Ressource Nom	Adresse/Région	Rôle**

Region	belgiumcentral	Bruxelles	Souveraineté & Latence
VNet	VNET-CORE	10.0.0.0/23	Enveloppe PME (512 IP)
Subnet Mgmt	Subnet-Management	10.0.0.0/27	Administration - accès unique via RDP lié dynamiquement à mon adresse IP
Subnet Id	Subnet-Identity	10.0.0.32/27	Coeur Infra : 2 DC (Haute disponibilité), AD DS, DNS intégré & Entra Connect
Subnet Data	Subnet-Data	10.0.1.0/24	Zone Métier : Segment pour les 150 collaborateurs (RH, Finance, IT, Sales).




 **Focus Stratégique :**
1. Identity (Le Cerveau) : Le choix du /27 permet d'accueillir deux contrôleurs de domaine pour la haute disponibilité et les mises à jour sans interruption de service.
2. Data (L'Efficience) : Un bloc /24 entier pour une lisibilité parfaite (10.0.1.x). L'isolation entre les services (RH, Finance...) est gérée logiquement pour protéger le trafic de données.



**Roadmap de Déploiement (Sprint 15 Jours - (cqfd les crédits azure étudiant)**

📂 Phase 1 : Network Foundation (✅)
* Provisionnement du VNet et des subnets segmentés.
* Sécurisation  via NSG (Network Security Groups).
* 
📂 Phase 2 : Identity & Hybrid Management ( 🔄)
* Déploiement du premier contrôleur de domaine sur Windows Server 2025 Core.
* Configuration de l'AD DS, du DNS interne et préparation du lien Microsoft Entra ID.
* 
📂 Phase 3 : System Hardening (⏳)
* Application de GPO de sécurité et durcissement des OS.
* Mise en place du RBAC (Role-Based Access Control).
