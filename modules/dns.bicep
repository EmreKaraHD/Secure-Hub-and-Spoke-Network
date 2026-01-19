@description('Name of the Private DNS Zone.')
param zoneName string = 'privatelink.database.windows.net'

@description('Resource ID of the VNet to link to.')
param vnetId string

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global' // Private DNS is a global resource
}

// Link to Virtual Network
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${last(split(vnetId, '/'))}-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: true // Auto-register VMs in this VNet
  }
}
