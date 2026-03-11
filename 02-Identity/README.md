📂 Étape 02 : Identity  

Infrastructure

📝 Description
Cette étape consiste en la mise en place du cœur de l'identité du réseau hybride. Elle comprend le déploiement d'un contrôleur de domaine (DC) sous Windows Server 2025 Core. L'accent est mis sur la réduction de la surface d'attaque (Zero-Trust) et l'automatisation du déploiement.


🏗️ Architecture & Stratégie

Spécifications de la VM
Paramètre	Configuration	Pourquoi ?
Nom	SRV-AD-01	Standard de nommage Identity.
Image	Windows Server 2025 Azure Edition Core	Support du Hotpatching et réduction de la surface d'attaque.
Réseau	VNET-CORE / Subnet-Identity	Segmentation réseau stricte.
IP Publique	None	Isolation totale d'Internet pour prévenir les scans.
Stockage	StandardSSD_LRS	Équilibre performance/coût.

*  Localisation : BelgiumCentral pour garantir la souveraineté des données et la cohérence avec le reste du VNet.  
*  Segmentation Réseau : Déploiement dans le Subnet-Identity (10.0.0.32/27) sans aucune adresse IP publique pour une isolation totale d'Internet.  
*  OS : Windows Server 2025 Core (Azure Edition) pour bénéficier du Hotpatching sans redémarrage.  


💻 Automatisation : Script 02-deploy-identity-vm.sh
Le script de déploiement a été conçu pour être idempotent, c'est-à-dire qu'il peut être exécuté plusieurs fois sans créer de doublons ou d'erreurs.

￼




Points clés du script :
*  Gestion des Secrets : Récupération dynamique des variables $VM_ADMIN et $VM_PASS via un fichier .env sécurisé. 
￼
*  Idempotence : Intégration d'une requête  (--query "[?name=='$VM_NAME'].name") pour vérifier si la VM existe déjà sur Azure avant de tenter la création. 
￼

*  Garde-fous : Utilisation de codes de sortie (if [ $? -eq 0 ]) pour valider chaque étape avant de passer à la suivante. 
* ￼





⚠️ Journal des complications & Arbitrages (Post-Mortem)
Durant le déploiement, nous avons rencontré deux obstacles majeurs qui ont nécessité des décisions d'ingénierie:


1. Indisponibilité des ressources (SkuNotAvailable)
*  Problème : La taille Standard_B2s n'était plus disponible en stock dans la région BelgiumCentral. 
* ￼

*  Résolution : Passage sur une instance Standard_D2s_v3, plus robuste et disponible, garantissant la continuité du projet.
* ￼
  
2. Le dilemme de l'Auto-Shutdown (FinOps vs Souveraineté)
*  Problème : Le service Microsoft.DevTestLab/schedules (nécessaire pour l'auto-shutdown) n'est pas activable sur la zone BelgiumCentral. 
* ￼
 
* Arbitrage technique : * Option A : Déplacer la VM en France pour gagner l'option FinOps.
    * Option B : Rester en Belgique pour la souveraineté et la cohérence réseau.
* Décision : Choix de la Souveraineté (Option B). La fonction d'auto-shutdown a été retirée du script pour privilégier une infrastructure stable et locale.    
🔒Configuration NSG (Network Security Group)
Le groupe de sécurité SRV-AD-01 NSG est configuré pour restreindre les flux:

*  Règle Inbound : Autorisation du port 3389 (RDP) via AllowVnetInBound.  
*  Sécurité par défaut : DenyAllInBound actif pour bloquer tout trafic non sollicité.

￼




📸 Preuve de création de SRV-AD-01 / VMnic / Iso

1. ￼




✅ État d'avancement
* [x] Segmentation VLSM du VNet effectuée.  
* [x] Provisioning de SRV-AD-01 fonctionnel (IP privée : 10.0.0.36).  
* [ ] Promotion du domaine pme150.local (Prochaine étape).

