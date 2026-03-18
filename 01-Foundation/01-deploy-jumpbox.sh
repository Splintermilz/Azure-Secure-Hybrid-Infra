#!/bin/bash
# =====================================================================
# SCRIPT: 01-deploy-jumpbox.sh
# DESCRIPTION: Deploys a secure management gateway (Jumpbox).
# STRATEGY: Zero Trust pivot point for internal RDP access.
# =====================================================================

# --- 1. Load & Check .env ---
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

# --- Variables ---
RG="RG-LAB-HYBRID-INFRA"
LOC="belgiumcentral"
VNET="VNET-CORE"
SUBNET="Subnet-Management"
VM_NAME="VM-JUMPBOX"

# --- Idempotency Check ---
CHECK_VM=$(az vm list -g "$RG" --query "[?name=='$VM_NAME'].name" -o tsv)

trap 'echo "Deployment failed. Check Azure connection."; exit 1' ERR

echo "-------------------------------------------------------"
echo "Starting Jumpbox Gateway Deployment: $VM_NAME ..."
echo "-------------------------------------------------------"

# --- 2. Public IP Creation (Idempotent by default in CLI) ---
az network public-ip create \
  --resource-group "$RG" \
  --name "PIP-JUMPBOX" \
  --sku Standard \
  --location "$LOC"

# --- 3. VM Creation (Hardened & Idempotent) ---
if [ -z "$CHECK_VM" ]; then
    echo "VM $VM_NAME does not exist. Starting deployment..."
    az vm create \
      --resource-group "$RG" \
      --name "$VM_NAME" \
      --image "MicrosoftWindowsServer:WindowsServer:2025-Datacenter-Core:latest" \
      --admin-username "$VM_ADMIN" \
      --admin-password "$VM_PASS" \
      --subnet "$SUBNET" \
      --vnet-name "$VNET" \
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
echo "-------------------------------------------------------"
