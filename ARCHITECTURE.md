# Deployment Architecture

## Overview

This repository deploys a complete backup infrastructure for testing and compliance:
- 4 Virtual Machines across 2 environments
- Recovery Services Vault with 2 backup policies
- Automated backup enablement for production VMs

## Resource Deployment Map

```
Subscription: 594e0bd0-2a8d-4419-b281-87869c20fd03
Location: australiaeast

rg-dev
├── vnet-dev (10.0.0.0/16)
│   └── default subnet (10.0.0.0/24)
├── vm-dev-001 (Ubuntu 22.04 LTS)
└── vm-dev-002 (Ubuntu 22.04 LTS)

rg-prod
├── vnet-prod (10.1.0.0/16)
│   └── default subnet (10.1.0.0/24)
├── vm-prod-001 (Ubuntu 22.04 LTS) ← Backup enabled (daily-2pm-35days)
├── vm-prod-002 (Ubuntu 22.04 LTS) ← Manual backup assignment available
└── rsv-prod-aue-001 (Recovery Services Vault)
    ├── daily-2pm-35days (Policy 1)
    └── daily-205pm-10days (Policy 2)
```

## Bicep Modules

### vm.bicep
Deploys a single Ubuntu 22.04 LTS virtual machine with:
- Network interface with dynamic IP
- Premium managed disk storage
- Automatic tagging for environment tracking

**Inputs:**
- `location` — Azure region
- `vmName` — VM name
- `vmSize` — VM SKU (default: Standard_B2s)
- `environment` — Environment tag (dev/prod)

**Outputs:**
- `vmId` — Full resource ID
- `vmName` — VM name
- `vmResourceGroup` — Resource group name

### rsv.bicep
Deploys a Recovery Services Vault for backup management:
- Locally Redundant Storage (LRS)
- Enhanced security enabled
- Soft delete enabled

**Inputs:**
- `location` — Azure region
- `vaultName` — Vault name

**Outputs:**
- `vaultId` — Full resource ID
- `vaultName` — Vault name
- `vaultResourceGroup` — Resource group name

### backup-policy.bicep
Deploys a backup policy for daily VM backups:
- Customizable backup time (24-hour format)
- Customizable retention duration
- Daily schedule with time zone support

**Inputs:**
- `vaultName` — Parent vault name
- `policyName` — Policy name
- `backupTime` — Backup time (format: "HH:mm", e.g., "14:00")
- `retentionDays` — Retention period

**Outputs:**
- `policyId` — Full resource ID
- `policyName` — Policy name

## Deployment Flow

### Stage 1: Validation
- Bicep templates are validated using `az bicep build`
- Syntax and schema errors are caught early

### Stage 2: Prerequisites
- Resource groups are created if they don't exist
- Virtual networks are provisioned for each environment
- Subnets are configured (10.0.0.0/24 for dev, 10.1.0.0/24 for prod)

### Stage 3: Infrastructure Deployment
- VMs are deployed using subscription-scoped deployment
- Recovery Services Vault is created in prod RG
- Backup policies are created and linked to the vault

### Stage 4: Backup Configuration (Optional)
- `enable-backup.ps1` script assigns Policy 1 to vm-prod-001
- Script uses Azure CLI for backup protection enablement
- Other VMs can be configured manually or via workflow input

## Backup Policies

### Policy 1: daily-2pm-35days
- **Schedule**: Daily at 14:00 (2:00 PM UTC)
- **Retention**: 35 days
- **Instant RP**: 5 days
- **Use case**: Production critical systems

### Policy 2: daily-205pm-10days
- **Schedule**: Daily at 14:05 (2:05 PM UTC)
- **Retention**: 10 days
- **Instant RP**: 5 days
- **Use case**: Non-critical or temporary resources

The 5-minute offset between policies prevents simultaneous backup jobs on the same vault.

## Security Considerations

- VMs use OIDC-based authentication (no stored credentials)
- Vault uses soft delete for accidental deletion protection
- Enhanced security is enabled on vault
- Resource tags enable RBAC and cost allocation
- Managed disks use Premium LRS storage

## Scalability

To deploy additional VMs:

1. Add module call in `main.bicep`:
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

2. Enable backup via script or Azure Portal:
   ```powershell
   ./scripts/enable-backup.ps1 `
     -VmName 'vm-prod-003' `
     -VaultName 'rsv-prod-aue-001' `
     -VaultResourceGroup 'rg-prod' `
     -VmResourceGroup 'rg-prod' `
     -PolicyName 'daily-2pm-35days'
   ```

## Cost Optimization

- Use Standard_B2s for dev/test VMs (burstable performance)
- Use LRS instead of GRS to reduce storage costs (~50% savings)
- Consider reserved instances for production VMs
- Monitor backup storage growth and adjust retention accordingly

## Integration with BackupComplianceAgent

This deployment repo works with [BackupComplianceAgent](../BackupComplianceAgent/) for:
1. **Compliance Scanning** — Verify backup status
2. **Policy Enforcement** — Detect non-compliant VMs
3. **Automated Remediation** — Apply policies to non-compliant resources

## Disaster Recovery

To protect against accidental deletion:
1. Enable vault-level soft delete (already configured)
2. Implement cross-region replication (change `GeoRedundant` in rsv.bicep)
3. Store IaC templates in git with proper access controls
4. Maintain backup restore test schedule

## Monitoring & Alerts

Recommended monitoring:
- Backup job status via Azure Portal or Azure Monitor
- Alert on failed backups
- Monitor vault storage usage
- Track RPO/RTO metrics against SLAs

Setup example:
```
Azure Monitor Alert Rules:
- "Backup Job Failed" → Email ops team
- "Vault Storage > 80%" → Email storage team
- "Daily Job Duration > 2 hours" → Investigate performance
```
