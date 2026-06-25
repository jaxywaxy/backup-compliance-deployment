param vaultName string
param policyName string
param backupTime string
param retentionDays int
param environment string = 'prod'
param tags object = {}

resource vault 'Microsoft.RecoveryServices/vaults@2023-04-01' existing = {
  name: vaultName
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: vault
  name: policyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '${backupTime}:00'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: retentionDays
          durationType: 'Days'
        }
      }
    }
  }
  tags: union({
    environment: environment
    managed: 'true'
  }, tags)
}

output policyId string = backupPolicy.id
output policyName string = backupPolicy.name
