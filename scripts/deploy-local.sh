#!/bin/bash
# Local deployment script for backup compliance infrastructure

set -e

SUBSCRIPTION_ID="594e0bd0-2a8d-4419-b281-87869c20fd03"
LOCATION="australiaeast"
ENVIRONMENT="${1:-prod}"
ENABLE_BACKUP="${2:-false}"

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  echo "❌ Invalid environment: $ENVIRONMENT"
  echo "Usage: ./scripts/deploy-local.sh [dev|prod] [true|false]"
  exit 1
fi

echo "🚀 Deploying backup compliance infrastructure"
echo "  Environment: $ENVIRONMENT"
echo "  Location: $LOCATION"
echo "  Subscription: $SUBSCRIPTION_ID"
echo ""

# Set subscription context
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource groups
echo "📁 Creating resource groups..."
for rg in "rg-dev" "rg-prod"; do
  az group create \
    --name "$rg" \
    --location "$LOCATION" \
    --tags managed=true \
    2>/dev/null || echo "  ℹ️  $rg already exists"
done

# Create virtual networks
echo "🌐 Creating virtual networks..."
az network vnet create \
  --resource-group rg-dev \
  --name vnet-dev \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.0.0/24 \
  2>/dev/null || echo "  ℹ️  vnet-dev already exists"

az network vnet create \
  --resource-group rg-prod \
  --name vnet-prod \
  --address-prefix 10.1.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.1.0.0/24 \
  2>/dev/null || echo "  ℹ️  vnet-prod already exists"

# Deploy infrastructure
echo "🔨 Deploying infrastructure..."
DEPLOYMENT_ID="backup-deployment-$(date +%s)"

az deployment sub create \
  --name "$DEPLOYMENT_ID" \
  --location "$LOCATION" \
  --subscription "$SUBSCRIPTION_ID" \
  --template-file bicep/main.bicep \
  --parameters "bicep/parameters/${ENVIRONMENT}.bicepparam"

# Enable backup on prod VM if requested
if [ "$ENVIRONMENT" = "prod" ] && [ "$ENABLE_BACKUP" = "true" ]; then
  echo ""
  echo "🔐 Enabling backup on vm-prod-001..."
  pwsh -Command "./scripts/enable-backup.ps1 \
    -VaultName 'rsv-prod-aue-001' \
    -VaultResourceGroup 'rg-prod' \
    -VmName 'vm-prod-001' \
    -VmResourceGroup 'rg-prod' \
    -PolicyName 'daily-2pm-35days' \
    -SubscriptionId '$SUBSCRIPTION_ID'"
fi

echo ""
echo "✅ Deployment completed!"
echo ""
echo "View resources:"
echo "  Azure Portal: https://portal.azure.com"
echo "  Resource Groups: rg-dev, rg-prod"
echo ""
echo "Verify deployment:"
echo "  az vm list --output table"
echo "  az backup vault list --output table"
