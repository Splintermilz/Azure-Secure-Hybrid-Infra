#  README — 01-Foundation

---

## 1. Localisation & Souveraineté

Le choix de la région conditionne à la fois la latence, la conformité réglementaire et la cohérence architecturale de l'ensemble du projet.

| Décision | Justification |
|---|---|
| Région `belgiumcentral` (Bruxelles) | Pour une PME basée en Belgique, cela garantit une latence minimale et respecte la souveraineté des données (RGPD), en maintenant les ressources sur le sol national. |
| Rejet de `westeurope` | Bien que plus répandue, cette région ne garantit pas la résidence des données en Belgique, ce qui compromet la conformité RGPD. |

---

## 2. Stratégie d'Adressage

Approche **"Zero Waste"** : un bloc de 512 IP offrant l'équilibre idéal entre économie de ressources Cloud et capacité d'évolution réelle.

| Ressource | Nom | CIDR | Rôle |
|---|---|---|---|
| VNet | `VNET-CORE` | `10.0.0.0/23` | Enveloppe Globale (512 IP) |
| Subnet Mgmt | `Subnet-Management` | `10.0.0.0/27` | Administration (Accès restreint par IP dynamique) |
| Subnet Id | `Subnet-Identity` | `10.0.0.32/27` | Cœur Identity — HA-Ready (2 DC) |
| Subnet IT | `Subnet-IT` | `10.0.1.0/26` | Zone dédiée aux administrateurs et outils IT |
| Subnet SALES | `Subnet-SALES` | `10.0.1.64/26` | Isolation des flux commerciaux |
| Subnet RH | `Subnet-RH` | `10.0.1.128/26` | Protection des données sensibles (Personnel) |
| Subnet FINANCE | `Subnet-FINANCE` | `10.0.1.192/26` | Zone critique (Flux comptables et bancaires) |

**Segmentation Technique (/27)** : Le choix du /27 pour Management et Identity sécurise l'évolution. Ce découpage permet d'accueillir immédiatement un second DC pour la Haute Disponibilité sans aucune reconfiguration réseau.

**Fusion AD DS + DNS** : Héberger les deux rôles sur le même hôte simplifie la résolution de noms interne tout en garantissant une réplication native des zones via l'Active Directory.

> **Arbitrage HA — MVP** : Suite à des instabilités d'agent Azure lors de la promotion du second nœud, la décision a été prise de maintenir un contrôleur de domaine unique (`10.0.0.36`) pour valider la Phase 3. Le terrain reste préparé pour une extension HA sans reconfiguration réseau.

### 🔄 Refactoring — Micro-Segmentation Métier (/26)

Le bloc initial `10.0.1.0/24` a été refactorisé en **4 segments distincts de 62 adresses** via le script `01-subnet-segmentation.sh`, passant d'une isolation monolithique à une granularité métier.

- **Sécurité Zero-Trust** : Chaque département est confiné dans son propre segment, limitant drastiquement la propagation latérale (*Lateral Movement*) en cas de compromission.
- **Héritage DNS** : Grâce à l'update global du VNet, chaque nouveau subnet pointe automatiquement vers `SRV-AD-01 (10.0.0.36)` pour la résolution de noms.
- **Évolutivité** : Cette structure permet d'appliquer des NSG granulaires par métier à l'étape suivante du projet.

```bash
# Validation de la création des subnets
az network vnet subnet list \
  -g RG-LAB-HYBRID-INFRA \
  --vnet-name VNET-CORE \
  -o table
```

---

## 3. Sécurité Native & Automatisation

- **Trap Error** : Gestion d'erreurs via la commande `trap` — intercepte tout échec Azure CLI et fournit un feedback immédiat, évitant tout déploiement partiel ou silencieusement défaillant.
- **Naming Convention** : Préfixes clairs (`RG-`, `VNET-`, `NSG-`) pour une maintenance facilitée — norme indispensable en entreprise.
- **Filtrage IP Dynamique** : Utilisation de `curl -s https://ifconfig.me` pour injecter automatiquement l'IP publique de l'administrateur dans le NSG. Le script est portable et sécurisé par défaut.
- **Least Privilege** : Accès RDP (port 3389) uniquement pour l'administrateur, avec priorité 100 dans le NSG pour garantir le traitement avant les règles de refus Azure.

> **Note sur la persistance de l'accès** : L'IP autorisée est capturée dynamiquement à l'exécution. En cas de changement d'adresse IP, il suffit de ré-exécuter le script ou de mettre à jour la règle manuellement dans le portail Azure.

> **Note Production** : Le filtrage IP sur le port 3389 constitue une première couche de défense. En entreprise, cette configuration serait complétée par un VPN Point-to-Site ou Azure Bastion pour supprimer totalement l'exposition RDP sur Internet.

---

## 4. Conclusion & Vision Long Terme

Mise en place d'un socle **Zero Trust** pour une infrastructure hybride. En privilégiant l'efficience opérationnelle sur le sur-dimensionnement, le réseau a été conçu pour :

- **Résister** : L'isolation stricte par NSG et la segmentation des rôles (IAM vs Data) limitent drastiquement la surface d'attaque latérale.
- **Évoluer** : Le `/23` laisse de larges plages libres pour de futurs services sans refaire le plan d'adressage, tout en restant sous la norme du /16.
- **Industrialiser** : L'usage systématique de l'automatisation (CLI) garantit un déploiement reproductible, rapide et sans erreur humaine.

> **But final** : Offrir à une PME un environnement Cloud souverain, sécurisé par défaut et prêt à accueillir des services critiques comme l'AD DS.

















