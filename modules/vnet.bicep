@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Virtual Network.')
param vnetName string

@description('Address space for the Virtual Network.')
param vnetAddressPrefix string

@description('List of subnets to create.')
param subnets array = []

@description('Tags for the resources, e.g. CostCenter, Env.')
param tags object = {}

// Create the Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    // Iterate over the subnets array to create subnets dynamically
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        // Conditionally apply NSG if provided
        networkSecurityGroup: contains(subnet, 'nsgId') ? {
            id: subnet.nsgId
        } : null
        // Conditionally apply Route Table if provided
        routeTable: contains(subnet, 'routeTableId') ? {
            id: subnet.routeTableId
        } : null
        // Enforcement policies for Private Endpoints/Links
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : 'Enabled'
        privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies') ? subnet.privateLinkServiceNetworkPolicies : 'Enabled'
      }
    }]
  }
}

// Output critical information for other modules to consume
output vnetId string = vnet.id
output vnetName string = vnet.name
output subnets array = [for (subnet, i) in subnets: {
  name: vnet.properties.subnets[i].name
  id: vnet.properties.subnets[i].id
  addressPrefix: vnet.properties.subnets[i].properties.addressPrefix
}]
