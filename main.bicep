@description('Location for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Address block for the Hub VNet. This should not overlap with Spoke VNets.')
param hubVnetPrefix string = '10.0.0.0/16'

var hubVnetName = 'vnet-hub'

// ============================================================================
// 1. Hub Virtual Network
// The central VNet that hosts shared services (Firewall, VPN Gateway).
// ============================================================================
module hubVnet 'modules/vnet.bicep' = {
  name: 'deploy-hub-vnet'
  params: {
    location: location
    vnetName: hubVnetName
    vnetAddressPrefix: hubVnetPrefix
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'ManagementSubnet'
        addressPrefix: '10.0.3.0/24'
      }
    ]
  }
}

// ============================================================================
// 2. Azure Firewall
// Security boundary that inspects traffic between Spokes and Inbound/Outbound.
// ============================================================================
module firewall 'modules/firewall.bicep' = {
  name: 'deploy-firewall'
  params: {
    location: location
    firewallName: 'fw-hub'
    firewallSubnetId: hubVnet.outputs.subnets[1].id // Assumes AzureFirewallSubnet is index 1
  }
}

// ============================================================================
// 3. Spoke Route Table
// User Defined Routes (UDR) to force Spoke traffic through the Firewall.
// ============================================================================
module routeTable 'modules/routetable.bicep' = {
  name: 'deploy-routetable'
  params: {
    location: location
    routeTableName: 'rt-spokes'
    nextHopIpAddress: firewall.outputs.privateIp
  }
}

// ============================================================================
// 4. Spoke Virtual Networks
// Workload VNets that are isolated from each other but peered to the Hub.
// ============================================================================

// Spoke 1 VNet
module spoke1Vnet 'modules/vnet.bicep' = {
  name: 'deploy-spoke1-vnet'
  params: {
    location: location
    vnetName: 'vnet-spoke1'
    vnetAddressPrefix: '10.1.0.0/16'
    subnets: [
      {
        name: 'WorkloadSubnet'
        addressPrefix: '10.1.1.0/24'
        routeTableId: routeTable.outputs.routeTableId
      }
    ]
  }
}

// Spoke 2 VNet
module spoke2Vnet 'modules/vnet.bicep' = {
  name: 'deploy-spoke2-vnet'
  params: {
    location: location
    vnetName: 'vnet-spoke2'
    vnetAddressPrefix: '10.2.0.0/16'
    subnets: [
      {
        name: 'WorkloadSubnet'
        addressPrefix: '10.2.1.0/24'
        routeTableId: routeTable.outputs.routeTableId
      }
    ]
  }
}

// ============================================================================
// 5. VNet Peering
// Connects Hub to Spokes and Spokes to Hub.
// 'allowGatewayTransit' on Hub side lets Spokes use the Hub's VPN Gateway.
// 'useRemoteGateways' on Spoke side tells them to send traffic to the Hub's Gateway.
// ============================================================================

// Peering Hub -> Spoke 1
module hubToSpoke1 'modules/peering.bicep' = {
  name: 'deploy-hub-to-spoke1'
  params: {
    peeringName: 'hub-to-spoke1'
    localVnetId: hubVnet.outputs.vnetId
    remoteVnetId: spoke1Vnet.outputs.vnetId
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

// Peering Spoke 1 -> Hub
module spoke1ToHub 'modules/peering.bicep' = {
  name: 'deploy-spoke1-to-hub'
  params: {
    peeringName: 'spoke1-to-hub'
    localVnetId: spoke1Vnet.outputs.vnetId
    remoteVnetId: hubVnet.outputs.vnetId
    allowGatewayTransit: false
    useRemoteGateways: true 
  }
}

// Peering Hub -> Spoke 2
module hubToSpoke2 'modules/peering.bicep' = {
  name: 'deploy-hub-to-spoke2'
  params: {
    peeringName: 'hub-to-spoke2'
    localVnetId: hubVnet.outputs.vnetId
    remoteVnetId: spoke2Vnet.outputs.vnetId
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

// Peering Spoke 2 -> Hub
module spoke2ToHub 'modules/peering.bicep' = {
  name: 'deploy-spoke2-to-hub'
  params: {
    peeringName: 'spoke2-to-hub'
    localVnetId: spoke2Vnet.outputs.vnetId
    remoteVnetId: hubVnet.outputs.vnetId
    allowGatewayTransit: false
    useRemoteGateways: true
  }
}

output hubVnetId string = hubVnet.outputs.vnetId
output spoke1VnetId string = spoke1Vnet.outputs.vnetId
output spoke2VnetId string = spoke2Vnet.outputs.vnetId

// ============================================================================
// 6. VPN Gateway
// Provides Site-to-Site connectivity to on-premises networks.
// ============================================================================
module vpnGateway 'modules/vpngateway.bicep' = {
  name: 'deploy-vpngateway'
  params: {
    location: location
    gatewayName: 'vpn-hub'
    gatewaySubnetId: hubVnet.outputs.subnets[0].id // Assumes GatewaySubnet is index 0
  }
}

// ============================================================================
// 7. Private DNS Zone
// Handles internal name resolution. Linked to the Hub VNet.
// ============================================================================
module privateDns 'modules/dns.bicep' = {
  name: 'deploy-privatedns'
  params: {
    zoneName: 'internal.corp'
    vnetId: hubVnet.outputs.vnetId
  }
}
// ============================================================================
// 8. Network Watcher
// Enables monitoring and diagnostics for the region.
// ============================================================================
module networkWatcher 'modules/networkwatcher.bicep' = {
  name: 'deploy-networkwatcher'
  params: {
    location: location
  }
}

