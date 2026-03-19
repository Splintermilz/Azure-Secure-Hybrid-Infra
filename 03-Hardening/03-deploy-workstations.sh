#!/bin/bash
# =============================================================
# 03-deploy-workstations.sh
# Phase 3 - Hardening | Azure Secure Hybrid Infrastructure
# Déploiement des VMs clientes par pôle métier
# Idempotent : vérifie l'existence avant création
# =============================================================

set -e
trap 'echo "Deployment failed. Check Azure connection."; exit 1' ERR

# --- Variables ---
RG="RG-LAB-HYBRID-INFRA"
LOC="belgiumcentral"
VNET="VNET-CORE"
VM_SIZE="Standard_B2s"
IMAGE="MicrosoftWindowsServer:WindowsServer:2022-datacenter-smalldisk:latest"
DNS_SERVER="10.0.0.36"

ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Error: Missing .env"; exit 1
fi

required_vars=("VM_ADMIN" "VM_PASS")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env"; exit 1
    fi
done

# --- Pôles et subnets associés ---
declare -A POLE_SUBNET=(
    ["IT"]="Subnet-IT"
    ["RH"]="Subnet-RH"
    ["Finance"]="Subnet-FINANCE"
    ["Sales"]="Subnet-SALES"
)

# =============================================================
# Fonction de déploiement d'une VM
# =============================================================
deploy_vm() {
    local POLE=$1
    local SUBNET=${POLE_SUBNET[$POLE]}
    local VM_NAME="WS-${POLE}-01"
    local NSG_NAME="${VM_NAME}NSG"

    echo ""
    echo "--- Deploying $VM_NAME ($POLE) ---"

    # CHECK idempotence
    CHECK_VM=$(az vm list -g $RG --query "[?name=='$VM_NAME'].name" -o tsv)
    if [ -n "$CHECK_VM" ]; then
        echo "[SKIP] $VM_NAME already exists."
        return
    fi

    # NSG
    az network nsg create \
        --resource-group $RG \
        --name $NSG_NAME \
        --location $LOC \
        --output none

    az network nsg rule create \
        --resource-group $RG \
        --nsg-name $NSG_NAME \
        --name "AllowRDPFromVNet" \
        --priority 1000 \
        --protocol Tcp \
        --destination-port-range 3389 \
        --source-address-prefixes "VirtualNetwork" \
        --access Allow \
        --output none

    # VM — sans IP publique, isolée dans son subnet métier
    az vm create \
        --resource-group $RG \
        --name $VM_NAME \
        --image $IMAGE \
        --vnet-name $VNET \
        --subnet $SUBNET \
        --nsg $NSG_NAME \
        --admin-username $VM_ADMIN \
        --admin-password $VM_PASS \
        --size $VM_SIZE \
        --public-ip-address "" \
        --storage-sku StandardSSD_LRS \
        --output none

    if [ $? -eq 0 ]; then
        echo "[OK] $VM_NAME deployed in $SUBNET."
    else
        echo "[ERROR] $VM_NAME deployment failed."; exit 1
    fi

    # Jonction au domaine via az vm run-command
    echo "    Joining $VM_NAME to pme150.local..."
    az vm run-command invoke \
        --resource-group $RG \
        --name $VM_NAME \
        --command-id RunPowerShellScript \
        --scripts "
            \$domain  = 'pme150.local'
            \$user    = 'pme150\\$VM_ADMIN'
            \$pass    = ConvertTo-SecureString '$VM_PASS' -AsPlainText -Force
            \$cred    = New-Object System.Management.Automation.PSCredential(\$user, \$pass)
            Add-Computer -DomainName \$domain -Credential \$cred -Restart -Force
        " \
        --output none

    echo "[OK] $VM_NAME joined to domain."
}

# =============================================================
# Déploiement de toutes les VMs
# =============================================================
for POLE in IT RH Finance Sales; do
    deploy_vm $POLE
done

# =============================================================
# Vérification finale
# =============================================================
echo ""
echo "--- Validation ---"
az vm list -g $RG --query "[?starts_with(name,'WS-')].{Name:name, State:powerState}" \
    --show-details -o table
