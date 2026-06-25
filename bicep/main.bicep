targetScope = 'subscription'

param location string = 'australiaeast'
param environment string
param vaultName string

// Reference resource groups (must exist)
resource devRg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: 'rg-dev'
}

resource prodRg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: 'rg-prod'
}

// Deploy VMs to dev resource group
module devVm1 'modules/vm.bicep' = {
  scope: devRg
  name: 'deploy-dev-vm1'
  params: {
    location: location
    vmName: 'vm-dev-001'
    environment: 'dev'
  }
}

module devVm2 'modules/vm.bicep' = {
  scope: devRg
  name: 'deploy-dev-vm2'
  params: {
    location: location
    vmName: 'vm-dev-002'
    environment: 'dev'
  }
}

// Deploy VMs to prod resource group
module prodVm1 'modules/vm.bicep' = {
  scope: prodRg
  name: 'deploy-prod-vm1'
  params: {
    location: location
    vmName: 'vm-prod-001'
    environment: 'prod'
  }
}

module prodVm2 'modules/vm.bicep' = {
  scope: prodRg
  name: 'deploy-prod-vm2'
  params: {
    location: location
    vmName: 'vm-prod-002'
    environment: 'prod'
  }
}

// Deploy Recovery Services Vault to prod resource group
module rsv 'modules/rsv.bicep' = {
  scope: prodRg
  name: 'deploy-rsv'
  params: {
    location: location
    vaultName: vaultName
  }
}

// Deploy backup policy 1: Daily at 2pm, retention 35 days
module backupPolicy1 'modules/backup-policy.bicep' = {
  scope: prodRg
  name: 'deploy-policy-daily-35d'
  params: {
    vaultName: vaultName
    policyName: 'daily-2pm-35days'
    backupTime: '14:00'
    retentionDays: 35
  }
  dependsOn: [rsv]
}

// Deploy backup policy 2: Daily at 2:05pm, retention 10 days
module backupPolicy2 'modules/backup-policy.bicep' = {
  scope: prodRg
  name: 'deploy-policy-daily-10d'
  params: {
    vaultName: vaultName
    policyName: 'daily-205pm-10days'
    backupTime: '14:05'
    retentionDays: 10
  }
  dependsOn: [rsv]
}

output deploymentSummary object = {
  vaultName: vaultName
  devVms: [
    devVm1.outputs.vmName
    devVm2.outputs.vmName
  ]
  prodVms: [
    prodVm1.outputs.vmName
    prodVm2.outputs.vmName
  ]
  policies: [
    'daily-2pm-35days'
    'daily-205pm-10days'
  ]
}
