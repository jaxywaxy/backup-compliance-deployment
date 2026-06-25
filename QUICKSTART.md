# Quick Start Guide

## Deploy in 3 Steps

### 1. Set Up GitHub Secrets (if using GitHub Actions)

In your GitHub repo settings → Secrets and variables → Actions, add:
- `AZURE_CLIENT_ID` — Your service principal client ID
- `AZURE_TENANT_ID` — Your Azure tenant ID

### 2. Trigger Deployment

**Option A: GitHub Actions (Recommended)**
- Go to **Actions** tab
- Select **Deploy Backup Compliance Infrastructure**
- Click **Run workflow**
- Select environment: `prod` (or `dev` to test)
- Check **Enable backup on prod VM** to assign policy to vm-prod-001

**Option B: Local Deployment**

```bash
# First, authenticate
az login --use-device-code

# Deploy to production
az deployment sub create \
  --name backup-deployment-prod \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/prod.bicepparam
```

### 3. Enable Backup (Automatic via GitHub Actions, or Manual)

**If using GitHub Actions:** Check the **Enable backup on prod VM** checkbox during workflow trigger.

**Manual (local):**
```powershell
./scripts/enable-backup.ps1 `
  -VaultName 'rsv-prod-aue-001' `
  -VaultResourceGroup 'rg-prod' `
  -VmName 'vm-prod-001' `
  -VmResourceGroup 'rg-prod' `
  -PolicyName 'daily-2pm-35days' `
  -SubscriptionId '594e0bd0-2a8d-4419-b281-87869c20fd03'
```

## What Gets Created

| Resource | Count | Location | Details |
|----------|-------|----------|---------|
| Virtual Machines | 4 | australiaeast | 2 in dev, 2 in prod |
| Network Interfaces | 4 | australiaeast | 1 per VM |
| Virtual Networks | 2 | australiaeast | 1 per environment |
| Recovery Services Vault | 1 | australiaeast (prod) | In rg-prod |
| Backup Policies | 2 | australiaeast | Daily @ 2pm (35d), 2:05pm (10d) |

## Verify Deployment

### Azure Portal
1. Go to **Resource Groups**
2. Check **rg-dev** and **rg-prod**
3. Verify 4 VMs are Running
4. Check **rsv-prod-aue-001** vault exists

### Azure CLI
```bash
# List VMs
az vm list --output table

# Check vault
az backup vault list --output table

# Check backup policies
az backup policy list \
  --vault-name rsv-prod-aue-001 \
  --resource-group rg-prod \
  --output table

# Check backup items (protected VMs)
az backup item list \
  --vault-name rsv-prod-aue-001 \
  --resource-group rg-prod \
  --output table
```

## Next Steps

### 1. Test Backup
```bash
# Trigger on-demand backup for vm-prod-001
az backup protection backup-now \
  --vault-name rsv-prod-aue-001 \
  --resource-group rg-prod \
  --container-name vm-prod-001 \
  --item-name vm-prod-001 \
  --retain-until <date> # e.g., 31-12-2026
```

### 2. Monitor Backups
- Azure Portal → Recovery Services Vault → Backup Jobs
- Or use: `az backup job list --vault-name rsv-prod-aue-001 --resource-group rg-prod`

### 3. Assign Backups to Other VMs
```powershell
# Enable backup for vm-prod-002 with policy 2
./scripts/enable-backup.ps1 `
  -VaultName 'rsv-prod-aue-001' `
  -VaultResourceGroup 'rg-prod' `
  -VmName 'vm-prod-002' `
  -VmResourceGroup 'rg-prod' `
  -PolicyName 'daily-205pm-10days'
```

### 4. Integrate with BackupComplianceAgent
Link this deployment with the [BackupComplianceAgent](../BackupComplianceAgent/) repo to:
- Scan compliance status
- Generate remediation plans
- Auto-apply backup policies

## Troubleshooting

### VMs won't deploy
- Check subscription ID: `594e0bd0-2a8d-4419-b281-87869c20fd03`
- Verify location: `australiaeast`
- Ensure you have Contributor permissions

### Backup won't enable
- Check vault exists in rg-prod
- Verify policy name: `daily-2pm-35days` or `daily-205pm-10days`
- Ensure VM is in running state

### Deployment fails with validation error
- Run: `az bicep build --file bicep/main.bicep`
- Check for syntax errors
- Ensure parameter files match template parameters

## Cleanup

```bash
# Delete all resources (be careful!)
az group delete --name rg-dev --yes
az group delete --name rg-prod --yes
```

## Support

- [ARCHITECTURE.md](ARCHITECTURE.md) — Detailed architecture documentation
- [README.md](README.md) — Full deployment guide
- [BackupComplianceAgent](../BackupComplianceAgent/) — Compliance scanning tool
