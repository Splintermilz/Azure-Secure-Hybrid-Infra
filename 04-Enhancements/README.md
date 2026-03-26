##  Ce que j'aurais aimé faire, avec plus de temps :

### Sécurité réseau
- **ASG (Application Security Groups)** : remplacer les règles NSG basées sur des IPs par des groupes logiques d'applications. Plus maintenable, plus lisible, et surtout plus proche d'une architecture production réelle.
- **Azure Bastion** : supprimer totalement l'exposition RDP sur Internet en passant par un accès HTTPS natif depuis le portail Azure. La Jumpbox n'aurait plus eu de raison d'être.
- **VPN Point-to-Site** : permettre aux administrateurs de se connecter au VNet depuis n'importe où, sans exposer aucun port public.

### Hardening Windows
- **Microsoft Defender for Endpoint** : augmenter le score de sécurité Windows Defender via les recommandations du portail Microsoft 365 Defender — activation de l'accès contrôlé aux dossiers, protection réseau, et réduction de la surface d'attaque (ASR rules).
- **CIS Benchmark via GPO** : appliquer les recommandations du Center for Internet Security pour Windows Server 2025 — durcissement supplémentaire sur les audits de connexion, désactivation des protocoles legacy comme NTLMv1, etc.


### IAM
- **MFA + Conditional Access (Entra ID)** : imposer l'authentification multi-facteurs et des politiques d'accès conditionnel (bloquer les connexions hors pays, exiger un appareil conforme, etc.).
- **Entra ID Connect** : synchroniser les identités AD locales vers le Cloud pour une gestion hybride unifiée — base indispensable pour Microsoft 365 en production.

### Monitoring & Résilience
- **Microsoft Sentinel** : SIEM Cloud-native pour centraliser les logs, détecter les anomalies et automatiser les réponses aux incidents.
- **Azure Monitor + Alertes** : supervision des métriques clés (CPU, connexions RDP, échecs d'authentification) avec alertes automatiques.
- **Second DC (SRV-AD-02)** : le terrain est préparé (`Subnet-Identity /27`), le déploiement d'un second contrôleur de domaine aurait apporté la Haute Disponibilité réelle de l'annuaire.

---
