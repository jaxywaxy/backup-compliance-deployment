@description('Azure region for deployment')
param location string

@description('Recovery Services Vault name')
param vaultName string

@description('Environment name')
param environment string = 'prod'

@description('Additional tags for the vault')
param tags object = {}

module vault 'br:mcr.microsoft.com/bicep/avm/res/recovery-services/vault:0.2.0' = {
  name: '${vaultName}-deploy'
  params: {
    name: vaultName
    location: location
    enableTelemetry: false
    backupConfig: {
      enhancedSecurityState: 'Enabled'
      softDeleteFeatureState: 'Enabled'
    }
    securitySettings: {
      publicNetworkAccess: 'Enabled'
    }
    tags: union({
      environment: environment
      managed: 'true'
    }, tags)
  }
}

output vaultId string = vault.outputs.resourceId
output vaultName string = vault.outputs.name
output vaultResourceGroup string = resourceGroup().name
