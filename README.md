# Backup Compliance Deployment

Infrastructure as Code for deploying 4 VMs (2 dev, 2 prod) with Recovery Services Vault and backup policies.

## Architecture

- **4 Virtual Machines**
  - 2 in `rg-dev` (vm-dev-001, vm-dev-002)
  - 2 in `rg-prod` (vm-prod-001, vm-prod-002)

- **Recovery Services Vault** (in rg-prod)
  - Location: australiaeast
  - Redundancy: Locally Redundant Storage (LRS)

- **2 Backup Policies**
  1. `daily-2pm-35days` — Daily at 2:00 PM, retain 35 days
  2. `daily-205pm-10days` — Daily at 2:05 PM, retain 10 days

## Prerequisites

- Azure subscription: `594e0bd0-2a8d-4419-b281-87869c20fd03`
- Azure CLI or PowerShell
- Bicep CLI (included with Azure CLI 2.20+)

## Deployment

### GitHub Actions (Recommended)

1. Add GitHub secrets:
   - `AZURE_CLIENT_ID` — Service principal client ID
   - `AZURE_TENANT_ID` — Azure tenant ID

2. Trigger workflow:
   - Go to **Actions** → **Deploy Backup Compliance Infrastructure**
   - Click **Run workflow**
   - Select environment (dev/prod)
   - Optionally enable backup for prod VM

### Local Deployment

```bash
# Login to Azure
az login

# Deploy to dev
az deployment sub create \
  --name backup-deployment-dev \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam

# Deploy to prod
az deployment sub create \
  --name backup-deployment-prod \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/prod.bicepparam

# Enable backup on prod VM
pwsh ./scripts/enable-backup.ps1 `
  -VaultName 'rsv-prod-aue-001' `
  -VaultResourceGroup 'rg-prod' `
  -VmName 'vm-prod-001' `
  -VmResourceGroup 'rg-prod' `
  -PolicyName 'daily-2pm-35days'
```

## File Structure

```
bicep/
├── main.bicep                 # Main deployment template
├── modules/
│   ├── vm.bicep              # VM module
│   ├── rsv.bicep             # Recovery Services Vault module
│   └── backup-policy.bicep   # Backup policy module
└── parameters/
    ├── dev.bicepparam        # Dev environment parameters
    └── prod.bicepparam       # Prod environment parameters

scripts/
└── enable-backup.ps1         # Enable backup on specific VM

.github/
└── workflows/
    └── deploy.yml            # GitHub Actions deployment workflow
```

## Backup Configuration

### Policy 1: Daily 2pm (35 days)
- **Schedule**: Daily at 14:00 (2:00 PM)
- **Retention**: 35 days
- **Assigned to**: vm-prod-001 (manual approval via workflow)

### Policy 2: Daily 2:05pm (10 days)
- **Schedule**: Daily at 14:05 (2:05 PM)
- **Retention**: 10 days
- **Assigned to**: (none by default)

## Manual Backup Assignment

To assign Policy 2 or change the backup policy for other VMs:

```powershell
az backup protection enable-for-vm \
  --vault-name rsv-prod-aue-001 \
  --resource-group rg-prod \
  --vm vm-prod-002 \
  --vm-resource-group rg-prod \
  --policy-name daily-205pm-10days
```

## Cleanup

To delete all deployed resources:

```bash
# Delete resource groups
az group delete --name rg-dev --yes
az group delete --name rg-prod --yes
```

## Notes

- VMs are deployed with Ubuntu 22.04 LTS
- VM size: Standard_B2s
- Authentication: Password-based (default username: azureuser)
- Vault uses Locally Redundant Storage (LRS) — change to GeoRedundant for HA

## Support

See [BackupComplianceAgent](../BackupComplianceAgent/) for compliance scanning and remediation automation.
