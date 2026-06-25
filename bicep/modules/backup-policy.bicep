param vaultName string
param policyName string
param backupTime string
param retentionDays int

resource vault 'Microsoft.RecoveryServices/vaults@2023-04-01' existing = {
  name: vaultName
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: vault
  name: policyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        backupTime
      ]
      scheduleWeeklyFrequency: 0
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          backupTime
        ]
        retentionDuration: {
          count: retentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

output policyId string = backupPolicy.id
output policyName string = backupPolicy.name
