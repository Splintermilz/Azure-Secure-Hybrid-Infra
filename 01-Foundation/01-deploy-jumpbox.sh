#!/bin/bash
# =====================================================================
# SCRIPT: 01-deploy-jumpbox.sh
# DESCRIPTION: Deploys a secure management gateway (Jumpbox).
# STRATEGY: Zero Trust pivot point for internal RDP access.
# =====================================================================

# 1. Load & Check .env
ENV_FILE="$(dirname "$0")/../.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Error: Missing .env file at $ENV_FILE"
    exit 1
fi

required_vars=("VM_ADMIN" "VM_PASS")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env file"
        exit 1
    fi
done

# Variables
RG="RG-LAB-HYBRID-INFRA"
LOC="belgiumcentral"
VNET="VNET-CORE"
SUBNET="Subnet-Management"
VM_NAME="VM-JUMPBOX"

# Idempotency Check
CHECK_VM=$(az vm list -g "$RG" --query "[?name=='$VM_NAME'].name" -o tsv)

trap 'echo "Deployment failed. Check Azure connection."; exit 1' ERR

echo "-------------------------------------------------------"
echo "Starting Jumpbox Gateway Deployment: $VM_NAME ..."
echo "-------------------------------------------------------"



# 2. Dynamic IP Calculation
# Why: Azure reserves .1 to .3. We target the 10th IP of the subnet range to avoid conflicts.
SUB_PREFIX=$(az network vnet subnet show -g "$RG" -n "$SUBNET" --vnet-name "$VNET" --query addressPrefix -o tsv | cut -d. -f1-3)
START_IP=$(az network vnet subnet show -g "$RG" -n "$SUBNET" --vnet-name "$VNET" --query addressPrefix -o tsv | cut -d. -f4 | cut -d/ -f1)
DYNAMIC_IP="${SUB_PREFIX}.$((START_IP + 10))"

echo "Calculated Private IP: $DYNAMIC_IP"

# 3. Public IP Creation 
az network public-ip create \
  --resource-group "$RG" \
  --name "PIP-JUMPBOX" \
  --sku Standard \
  --location "$LOC"



# 4. VM Creation (Hardened & Dynamic IP) 
if [ -z "$CHECK_VM" ]; then
    echo "VM $VM_NAME does not exist. Starting deployment..."
    az vm create \
      --resource-group "$RG" \
      --name "$VM_NAME" \
      --image "MicrosoftWindowsServer:WindowsServer:2025-Datacenter-Core:latest" \
      --admin-username "$VM_ADMIN" \
      --admin-password "$VM_PASS" \
      --vnet-name "$VNET" \
      --subnet "$SUBNET" \
      --private-ip-address "$DYNAMIC_IP" \
      --public-ip-address "PIP-JUMPBOX" \
      --nsg "NSG-MGMT-ADMIN" \
      --size Standard_D2s_v3 \
      --storage-sku StandardSSD_LRS
else
    echo "VM $VM_NAME already exists. Skipping creation."
fi

echo "-------------------------------------------------------"
echo "SUCCESS: Jumpbox is ready."
echo "Public IP: $(az network public-ip show -g "$RG" -n "PIP-JUMPBOX" --query ipAddress -o tsv)"
echo "Private IP: $DYNAMIC_IP"
echo "-------------------------------------------------------""
