@description('Name of the peering resource.')
param peeringName string

@description('Resource ID of the local VNet.')
param localVnetId string

@description('Resource ID of the remote VNet.')
param remoteVnetId string

@description('Allow Gateway Transit. Set to true on Hub side.')
param allowGatewayTransit bool = false

@description('Use Remote Gateways. Set to true on Spoke side.')
param useRemoteGateways bool = false

// Peering resource
// Note: Peering must be established in BOTH directions (A->B and B->A)
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: '${last(split(localVnetId, '/'))}/${peeringName}' // Nested resource syntax workaround if not referencing parent
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: true // Traffic allowed
    allowForwardedTraffic: true // Traffic forwarded by NVA/Firewall allowed
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}
