@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Firewall.')
param firewallName string

@description('Resource ID of the AzureFirewallSubnet. Must be named exactly "AzureFirewallSubnet".')
param firewallSubnetId string

// Public IP for the Firewall (Standard SKU required for most features)
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'pip-${firewallName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Basic Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-04-01' = {
  name: 'policy-${firewallName}'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

// Default Rule Collection Group
resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'AllowAll'
        priority: 100
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowAllTraffic'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

// Azure Firewall Instance
resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'configuration'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

output privateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
