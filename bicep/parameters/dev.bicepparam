using '../main.bicep'

param location = 'australiaeast'
param environment = 'dev'
param vaultName = 'rsv-dev-aue-001'
param sshPublicKey = '' // Use SSH key for production, or leave empty to use password
param adminPassword = 'TestPass@123!dev' // Change for production - use SSH keys instead
