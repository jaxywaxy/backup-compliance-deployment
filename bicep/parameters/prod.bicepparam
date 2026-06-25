using '../main.bicep'

param location = 'australiaeast'
param environment = 'prod'
param vaultName = 'rsv-prod-aue-001'
param sshPublicKey = '' // Use SSH key for production, or leave empty to use password
param adminPassword = 'TestPass@123!prod' // Change for production - use SSH keys instead
