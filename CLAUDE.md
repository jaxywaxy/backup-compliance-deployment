# Backup Compliance Deployment — Claude Code Guidelines

## Project Context

This is an Infrastructure as Code (IaC) repository for deploying Azure backup infrastructure:
- 4 Virtual Machines (2 dev, 2 prod)
- Recovery Services Vault with 2 backup policies
- GitHub Actions automation for deployment
- Integration with BackupComplianceAgent for compliance scanning

**Key Details:**
- Subscription: `594e0bd0-2a8d-4419-b281-87869c20fd03`
- Location: `australiaeast`
- Resource Groups: `rg-dev`, `rg-prod`
- Vault Name: `rsv-prod-aue-001`

## Bicep Standards

- **Module pattern**: Each resource type has its own module in `bicep/modules/`
- **Parameters**: Environment-specific values in `bicep/parameters/*.bicepparam`
- **Naming convention**: `{resource-type}-{environment}-{location}-{sequence}`
  - Example: `vm-prod-001`, `rsv-prod-aue-001`
- **Resource Groups**: Referenced as existing (must be created before deployment)
- **Tags**: All resources tagged with `environment` and `managed: 'true'`

## Deployment Workflow

The GitHub Actions workflow (`deploy.yml`) follows these stages:
1. **Validate** — `az bicep build` all templates
2. **Create prerequisites** — Resource groups, VNets, subnets
3. **Deploy** — `az deployment sub create` with bicepparam files
4. **Configure backups** — Optional backup assignment via PowerShell

**Important:** The workflow uses OIDC authentication (no secrets stored in code).

## Common Tasks

### Add a new VM
1. Add module call in `bicep/main.bicep`:
   ```bicep
   module newVm 'modules/vm.bicep' = {
     scope: prodRg
     name: 'deploy-prod-vm3'
     params: {
       location: location
       vmName: 'vm-prod-003'
       environment: 'prod'
     }
   }
   ```
2. Assign backup via `scripts/enable-backup.ps1` or GitHub Actions

### Add a new backup policy
1. Add module call in `bicep/main.bicep`:
   ```bicep
   module backupPolicy3 'modules/backup-policy.bicep' = {
     scope: prodRg
     name: 'deploy-policy-custom'
     params: {
       vaultName: vaultName
       policyName: 'custom-schedule'
       backupTime: '15:00'
       retentionDays: 14
     }
     dependsOn: [rsv]
   }
   ```
2. Update parameter files if needed
3. Test locally before merging

### Modify VM sizing or image
Edit `bicep/modules/vm.bicep`:
- Change `vmSize` parameter default or in main.bicep
- Update `imageReference` section for different OS
- Ensure changes are tested in dev first

## Testing

### Local validation
```bash
# Validate all bicep files
find bicep -name '*.bicep' | while read file; do
  az bicep build --file "$file" --outdir /tmp
done
```

### Local deployment (dev)
```bash
az deployment sub create \
  --name backup-test-$(date +%s) \
  --location australiaeast \
  --template-file bicep/main.bicep \
  --parameters bicep/parameters/dev.bicepparam
```

### Cleanup
```bash
az group delete --name rg-dev --yes --no-wait
az group delete --name rg-prod --yes --no-wait
```

## Git Workflow

- **Main branch**: Production-ready code
- **Feature branches**: For new VMs, policies, or workflow changes
- **PR requirements**:
  - GitHub Actions validation must pass
  - Bicep templates must be syntactically valid
  - Documentation (README, QUICKSTART) must be updated

## Documentation

- **README.md** — Overview and full deployment guide
- **QUICKSTART.md** — 3-step quick deployment
- **ARCHITECTURE.md** — Detailed architecture, scaling, security
- **CLAUDE.md** (this file) — Developer guidelines

Update these when:
- Adding new resources or modules
- Changing deployment process
- Adding new backup policies
- Modifying naming conventions

## Integration

This repo works with:
- **BackupComplianceAgent** — Scans backup compliance and remediates
- **GitHub Actions** — Automated deployment and validation
- **Azure CLI** — Local deployment and management

## Secrets & Configuration

### GitHub Secrets Required
- `AZURE_CLIENT_ID` — Service principal client ID
- `AZURE_TENANT_ID` — Azure tenant ID

### GitHub Variables (optional)
- `SUBSCRIPTION_ID` — Can override default subscription

### Local `.env` (not committed)
```
AZURE_SUBSCRIPTION_ID=594e0bd0-2a8d-4419-b281-87869c20fd03
AZURE_TENANT_ID=<your-tenant-id>
```

## Performance & Cost

- **VM Size**: Standard_B2s (burstable, cost-effective for dev/test)
- **Storage**: Premium LRS (faster than Standard, cheaper than GRS)
- **Backup retention**: Policy 1 = 35d, Policy 2 = 10d
- **Cost estimate**: ~$50-80/month for this infrastructure

To optimize:
- Use Azure Hybrid Benefit for Windows VMs
- Consider reserved instances for prod
- Monitor backup storage growth

## Common Issues

| Issue | Solution |
|-------|----------|
| "Resource group not found" | Create rg-dev and rg-prod first |
| "VNet not found" | Run deployment workflow to create prerequisites |
| "Backup won't enable" | Ensure vault exists, VM is running, policy exists |
| "Deployment timeout" | Check Azure service health, retry with new timestamp |

## Maintainers

- Current: Development team
- Review: Backup/Infrastructure team before prod deployments

## Drift Detection

A comprehensive drift detection system is included in the `drift-detection/` folder. See [drift-detection/docs/DRIFT_DETECTION_GUIDE.md](drift-detection/docs/DRIFT_DETECTION_GUIDE.md) for full documentation.

**Quick start:**

```bash
cd drift-detection
./DRIFT_QUICK_START.sh setup
./DRIFT_QUICK_START.sh check
```

## Related Repositories

- [BackupComplianceAgent](../BackupComplianceAgent/) — Compliance scanning & remediation
