# =====================================================================
# SCRIPT: 02-deploy-identity-vm.sh
# DESCRIPTION: Provisioning the first domain controller (DC) via Azure CLI
# ARCHITECTURE: Windows Server 2025 Core in Subnet-Identity (10.0.0.32/27)
# STRATEGY: Zero-Trust & Hardening - No public IP, reduced attack surface (Core)
# =====================================================================
#
# 1. Set up .env to dynamically retrieve the VM_ADMIN, VM_PASS and AMDIN_MAIL variables

ENV_FILE="$(dirname "$0")/../.env"

if [ -f $ENV_FILE ]; then
    	source $ENV_FILE
else
    echo "Error : Missing .env"
    exit 1
fi

# ---  Check if required environment variables are set ---
required_vars=("VM_ADMIN" "VM_PASS" "ADMIN_MAIL")
for var in "${required_vars[@]}"; do
    if [ -z ${!var} ]; then
        echo "Error: $var is not set in .env file"
        exit 1
    fi
done

# --- Variables ---
RG="RG-LAB-HYBRID-INFRA"
LOC="belgiumcentral"
VM_NAME="SRV-AD-01"
VNET="VNET-CORE"
SUBNET="Subnet-Identity"
CHECK_VM=$(az vm list -g $RG --query "[?name=='$VM_NAME'].name" -o tsv)
trap 'echo "Deployment failed. Check Azure connection."; exit 1' ERR

echo "Deployment of the VM identity : $VM_NAME ..."


# 2. VM creation  (Hardened)
# Why : Absence of a public IP address  for isolation from the internet and prevents scans
# Image : Datacenter-Azure-Edition-Core for Hotpatching
# CHEK_VM : makes idempotent VM creation 
if [ -z "$CHECK_VM" ]; then
	echo "VM $VM_NAME do not exist yet. Starting deployment ..."
az vm create \
  --resource-group $RG \
  --name $VM_NAME \
  --image "MicrosoftWindowsServer:WindowsServer:2025-Datacenter-Azure-Edition-Core:latest" \
  --vnet-name $VNET \
  --subnet $SUBNET \
  --admin-username $VM_ADMIN \
  --admin-password $VM_PASS \
  --size Standard_D2s_v3 \
  --public-ip-address "" \
  --storage-sku StandardSSD_LRS

    if [ $? -eq 0 ]; then
        echo "-------------------------------------------------------"
        echo "SUCCESS: VM $VM_NAME is created !"
        echo "-------------------------------------------------------"
    else
        echo "Error: VM $VM_NAME creation failed. Stopping script."
        exit 1
    fi
else
    echo "VM $VM_NAME already exists. Skipping creation."
fi



# 3. FinOps : Auto-shutdown at 7pm
# Why : Azure credit economy / FinOps mindset
echo "Configuration of auto-shutdown at 7pm (Brussels Time)..."

az vm auto-shutdown \
  --resource-group $RG \
  --name $VM_NAME \
  --time 1900 \
  --location $LOC \
  --email $ADMIN_MAIL # To receive an auto-shutdown confirmation email

if [ $? -eq 0 ]; then
    echo "-------------------------------------------------------"
    echo "SUCCESS: Auto-shutdown is enabled."
    echo "-------------------------------------------------------"
else
    echo "Error: VM created, but Auto-shutdown configuration failed."
fi
