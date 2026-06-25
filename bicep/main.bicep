targetScope = 'subscription'

@description('Azure region for deployment')
param location string = 'australiaeast'

@description('Environment name (dev or prod)')
@allowed(['dev', 'prod'])
param environment string

@description('Recovery Services Vault name')
@minLength(2)
@maxLength(50)
param vaultName string

@description('SSH public key for VM access')
param sshPublicKey string = ''

@description('Admin password for VMs (required if SSH key not provided)')
@secure()
param adminPassword string = ''

param subscriptionId string = subscription().subscriptionId

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
    vnetResourceGroupName: devRg.name
    subscriptionId: subscriptionId
    sshPublicKey: sshPublicKey
    adminPassword: adminPassword
  }
}

module devVm2 'modules/vm.bicep' = {
  scope: devRg
  name: 'deploy-dev-vm2'
  params: {
    location: location
    vmName: 'vm-dev-002'
    environment: 'dev'
    vnetResourceGroupName: devRg.name
    subscriptionId: subscriptionId
    sshPublicKey: sshPublicKey
    adminPassword: adminPassword
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
    vnetResourceGroupName: prodRg.name
    subscriptionId: subscriptionId
    sshPublicKey: sshPublicKey
    adminPassword: adminPassword
  }
}

module prodVm2 'modules/vm.bicep' = {
  scope: prodRg
  name: 'deploy-prod-vm2'
  params: {
    location: location
    vmName: 'vm-prod-002'
    environment: 'prod'
    vnetResourceGroupName: prodRg.name
    subscriptionId: subscriptionId
    sshPublicKey: sshPublicKey
    adminPassword: adminPassword
  }
}

// Deploy Recovery Services Vault to prod resource group
module rsv 'modules/rsv.bicep' = {
  scope: prodRg
  name: 'deploy-rsv'
  params: {
    location: location
    vaultName: vaultName
    environment: environment
  }
}

output deploymentSummary object = {
  vaultName: vaultName
  vaultResourceGroup: prodRg.name
  devVms: [
    devVm1.outputs.vmName
    devVm2.outputs.vmName
  ]
  prodVms: [
    prodVm1.outputs.vmName
    prodVm2.outputs.vmName
  ]
  backupPolicies: [
    'Create policies manually or via enable-backup.ps1 script'
  ]
}
