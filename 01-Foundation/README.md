# **README - 01-Foundation :**

<br>
<br>

## **1. Localisation & Souveraineté**
* ***Décision :*** Utilisation de la région belgiumcentral (Bruxelles) plutôt que westeurope.
* ***Pourquoi :*** Pour une PME basée en Belgique, cela garantit une latence minimale et respecte la souveraineté des données (RGPD), en gardant les ressources sur le sol national. 

<br>
---
<br>


## **2. Stratégie d'Adressage**
J'ai opté pour une approche "Zero Waste" (512 IP), équilibre idéal entre économie de ressources et capacité d'évolution.

* ***VNet Global (/23) :*** 512 adresses au total. C'est l'équilibre parfait entre économie de ressources et capacité d'évolution, le /24 étant moins intéressant pour ce dernier point.

* ***Segmentation Technique (/27) :*** Pour Management et Identity.
    * *Réflexion :* Le choix du /27 (27 IP utilisables) sécurise l'évolution. Bien que l'infrastructure actuelle repose sur un contrôleur de domaine unique (SRV-AD-01), ce découpage permet d'accueillir immédiatement un second nœud pour la Haute Disponibilité (HA) sans reconfiguration réseau.

    * *Réflexion :* La fusion des rôles AD DS et DNS sur le même hôte simplifie la résolution de noms interne, tout en garantissant une réplication native des zones via l'Active Directory.



[!IMPORTANT]
Arbitrage de Phase 2 : L'infrastructure est configurée en "HA-Ready". Suite à des instabilités d'agent Azure lors de la promotion du second nœud, la décision a été prise de maintenir un contrôleur de domaine unique (10.0.0.36) pour valider la Phase 3. Cette approche privilégie l'agilité et le respect des délais du projet (MVP - Minimum Viable Product).





* ***Segmentation Métier (/24) :*** Pour le sous-réseau Data.
    * *Réflexion :* Un bloc entier pour les départements (RH, Finance, IT, Sales) afin de garder une lisibilité parfaite (10.0.1.x) et d'accueillir des potentiels futurs collaborateurs.
				  De plus, cela permet d’isoler le traffic de données du trafic de gestion (management).



* ### 🔄 Update : Segmentation Métier Dynamique

Afin de concrétiser cette réflexion, j'ai procédé à un **refactoring dynamique** du réseau via mon script `01-subnet-segmentation.sh`. L'idée est de passer d'un bloc monolithique à une isolation granulaire.

#### Implémentation technique d'une micro-segmentation (CIDR /26)
J'ai découpé le bloc initial `10.0.1.0/24` en **4 segments distincts** de 62 adresses utilisables chacun :

* **Subnet-IT** (`10.0.1.0/26`) : Zone uniquement dédié au personnel IT. 
* **Subnet-SALES** (`10.0.1.64/26`) : Isolation des flux commerciaux.
* **Subnet-RH** (`10.0.1.128/26`) : Protection des données sensibles du personnel.
* **Subnet-FINANCE** (`10.0.1.192/26`) : Zone critique pour les flux comptables.

#### Bénéfices immédiats
1.  **Sécurité (Zero-Trust)** : Chaque département est confiné dans son propre segment, limitant la surface d'attaque latérale en cas de compromission d'une station.
2.  **Héritage DNS** : Grâce à l'update global du VNet, chaque nouveau subnet pointe automatiquement vers mon contrôleur de domaine `SRV-AD-01` (`10.0.0.36`) pour la résolution de noms.
3.  **Évolutivité** : Cette structure nous permet d'appliquer des **NSG** granulaires par métier, à l'étape suivante du projet.
 
> [!TIP]
> **Vérification du déploiement :** > On peut valider la création des subnets avec la commande suivante :  
> `az network vnet subnet list -g RG-LAB-HYBRID-INFRA --vnet-name VNET-CORE -o table`


<br>
---
<br>


## **3. Sécurité Native & Automatisation**
* ***Trap Error :*** Pour améliorer la fiabilité du déploiement, j'ai intégré une gestion d'erreurs via la commande trap. Cela permet d'intercepter tout échec de commande Azure CLI et de fournir un feedback immédiat, évitant ainsi un déploiement partiel ou silencieusement défaillant.

* ***Naming Convention :*** Utilisation de préfixes clairs (RG-, VNET-, NSG-) pour une maintenance facilitée, norme indispensable en entreprise.

* ***Filtrage IP Dynamique :*** Utilisation de curl -s https://ifconfig.me pour injecter automatiquement mon IP publique dans le pare-feu (NSG). Le script est donc portable et sécurisé par défaut.

* ***Note sur la persistance de l'accès :*** L'adresse IP autorisée est capturée dynamiquement au moment de l'exécution du script. Pour un projet de portfolio, ce choix privilégie la sécurité Zero Trust (fermeture totale par défaut). En cas de changement de lieu ou d'adresse IP publique de l'administrateur, il suffit de ré-exécuter le script ou de mettre à jour la règle manuellement dans le portail Azure pour rétablir l'accès.

* ***Priorité 100 :*** J'ai assigné une priorité de 100 à la règle d'accès RDP pour garantir qu'elle soit traitée en priorité  par le NSG, avant les règles de refus par défaut d'Azure. Ce choix permet d'assurer l'accès administratif tout en gardant une plage de manœuvre pour des règles futures.

* ***Least Privilège :*** accès RDP uniquement pour l’administrateur (moi).


***Note :*** *Le filtrage par IP publique sur le port 3389 constitue une première couche de défense.*
*Pour une infrastructure d'entreprise, cette configuration serait complétée par un VPN Point-to-Site ou Azure Bastion afin de supprimer totalement l'exposition du port RDP sur Internet.*



<br>
---
<br>



## **- Conclusion & Vision Long Terme -**

Mise en place d'un socle Zero Trust pour une infrastructure hybride. En privilégiant l'efficience opérationnelle sur le sur-dimensionnement, j'ai conçu un réseau capable de :

* ***Résister :*** * L'isolation stricte par NSG et la segmentation des rôles (IAM vs Data) limitent drastiquement la surface d'attaque.

* ***Évoluer :*** Le /23 laisse encore de larges plages libres pour de futurs services sans refaire le plan d'adressage, tout en évitant un gaspillage important en restant sous la norme du /16.

* ***Industrialiser :*** L'usage systématique de l'automatisation (CLI) garantit un déploiement reproductible, rapide et sans erreur humaine.

***Le But final :*** Offrir à une PME un environnement Cloud souverain, sécurisé par défaut et prêt à accueillir des services critiques comme l'AD DS.



















