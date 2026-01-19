@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the VPN Gateway.')
param gatewayName string

@description('Resource ID of the GatewaySubnet. Must be named exactly "GatewaySubnet".')
param gatewaySubnetId string

// Public IP for the VPN Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-${gatewayName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Virtual Network Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: gatewayName
  location: location
  properties: {
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
