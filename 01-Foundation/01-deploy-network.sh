#!/bin/bash
# =====================================================================
# SCRIPT: 01-deploy-network.sh
# DESCRIPTION: Deploys the core Azure networking infrastructure.
# ARCHITECTURE: Hub-style VNet with Management & Identity segmentation.
# STRATEGY: Zero Trust - All inbound traffic is blocked except for Admin IP.
# =====================================================================

# --- Variables ---
RG="RG-LAB-HYBRID-INFRA"
LOC="belgiumcentral"
VNET_NAME="VNET-CORE"
MY_IP=$(curl -s https://ifconfig.me) # https://ifconfig.me : to retrieve my public IP


trap 'echo "Deployment failed. Check Azure connection."; exit 1' ERR



echo "-------------------------------------------------------"
echo "Starting Azure Foundation Deployment..."
echo "-------------------------------------------------------"



# 1. Resource Group creation
# Why: Logical container for lifecycle management and RBAC.
az group create --name $RG --location $LOC




# 2. Network Security Group (NSG) setup
# Why: Acts as a Layer 4 firewall. Created first to ensure security from the start.
az network nsg create --resource-group $RG --name "NSG-MGMT-ADMIN"




# 3. Security Rule: Restrict RDP access
# Why: Ports like 3389 (RDP) are highly targeted
# How: Add only my current public IP ($MY_IP).
az network nsg rule create \
  --resource-group $RG \
  --nsg-name "NSG-MGMT-ADMIN" \
  --name "Allow-RDP-From-Home" \
  --priority 100 \
  --source-address-prefixes $MY_IP \
  --destination-port-ranges 3389 \
  --access Allow \
  --protocol Tcp \
  --description "Secure admin access"



# 4. VNet & Management Subnet (Ultra-Efficient)
# Why: Using /23 (512 IPs) to perfectly match SME needs and minimize IP waste.
az network vnet create \
  --name $VNET_NAME \
  --resource-group $RG \
  --location "belgiumcentral" \
  --address-prefix 10.0.0.0/23 \
  --subnet-name "Subnet-Management" \
  --subnet-prefix 10.0.0.0/27 \
  --network-security-group "NSG-MGMT-ADMIN"



# 5. Identity Subnet (Domain Controllers)
az network vnet subnet create \
  --name "Subnet-Identity" \
  --address-prefix 10.0.0.32/27 \
  --resource-group $RG \
  --vnet-name $VNET_NAME

# 6. Data Subnet (File Services for HR, Finance, IT, Sales)
az network vnet subnet create \
  --name "Subnet-Data" \
  --address-prefix 10.0.1.0/24 \
  --resource-group $RG \
  --vnet-name $VNET_NAME


echo "-------------------------------------------------------"
echo "SUCCESS: Network Infrastructure is live."
echo "-------------------------------------------------------"
