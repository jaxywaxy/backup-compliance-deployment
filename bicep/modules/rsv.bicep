param location string
param vaultName string

resource vault 'Microsoft.RecoveryServices/vaults@2023-04-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    redundancySettings: {
      crossRegionRestore: 'Disabled'
      standardTierStorageRedundancy: 'LocallyRedundant'
    }
  }
}

resource vaultBackupConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2023-04-01' = {
  parent: vault
  name: 'vaultconfig'
  properties: {
    enhancedSecurityState: 'Enabled'
    softDeleteFeatureState: 'Enabled'
    resourceGuardOperationRequests: []
  }
}

output vaultId string = vault.id
output vaultName string = vault.name
output vaultResourceGroup string = resourceGroup().name
