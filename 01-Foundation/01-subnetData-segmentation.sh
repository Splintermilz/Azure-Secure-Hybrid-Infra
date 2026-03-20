#!/bin/bash
# ==============================================================================
# SCRIPT: 01-subnet-segmentation.sh
# DESCRIPTION: Refactors the broad Subnet-Data (/24) into 4 specialized /26 subnets.
# ARCHITECTURE: Micro-segmentation for RH, Sales, IT, and Finance departments.
# STRATEGY: Zero Trust - Isolating department traffic at the network level.
# ==============================================================================

# Variables
RG="RG-LAB-HYBRID-INFRA"
VNET_NAME="VNET-CORE"

trap 'echo "Segmentation failed. Check Azure connection or subnet usage."; exit 1' ERR

echo "--------------------------------------------------"
echo "Starting Subnet Data Segmentation..."
echo "--------------------------------------------------"

# 1. Remove the legacy broad Subnet-Data
# Why: To replace the /24 with more granular segments without IP overlap.
# How: Deleting the existing subnet (Ensure no resources are attached first).
az network vnet subnet delete \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name "Subnet-Data"

# 2. Create segmented subnets (/26 - 64 IPs each)
# Why: Apply the principle of least privilege per department.
# How: Sequential CIDR allocation within the 10.0.1.0 range.

# IT
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name "Subnet-IT" \
  --address-prefixes "10.0.1.0/26"

# SALES
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name "Subnet-SALES" \
  --address-prefixes "10.0.1.64/26"

# HR
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name "Subnet-HR" \
  --address-prefixes "10.0.1.128/26"

# FINANCE
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name "Subnet-FINANCE" \
  --address-prefixes "10.0.1.192/26"

echo "--------------------------------------------------"
echo "Segmentation successfully completed."
echo "--------------------------------------------------"
