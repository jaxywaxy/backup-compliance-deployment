@description('Azure region for deployment')
param location string

@description('Virtual machine name')
param vmName string

@description('VM size (SKU)')
param vmSize string = 'Standard_B2s'

@description('Admin username for VM access')
param adminUsername string = 'azureuser'

@description('SSH public key for key-based authentication')
@secure()
param sshPublicKey string = ''

@description('Environment name')
param environment string

@description('Virtual network resource group name')
param vnetResourceGroupName string

@description('Azure subscription ID')
param subscriptionId string

// Reference the existing virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(subscriptionId, vnetResourceGroupName)
  name: 'vnet-${environment}'
}

// Reference the default subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  parent: vnet
  name: 'default'
}

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: !empty(sshPublicKey)
        ssh: !empty(sshPublicKey) ? {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        } : null
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: {
    environment: environment
    managed: 'true'
  }
}

output vmId string = vm.id
output vmName string = vm.name
output vmResourceGroup string = resourceGroup().name
