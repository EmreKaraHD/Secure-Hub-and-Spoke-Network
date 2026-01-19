@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Route Table.')
param routeTableName string

@description('Next hop IP address (Firewall Private IP).')
param nextHopIpAddress string

// Route Table with a default route (0.0.0.0/0) pointing to the Firewall
resource routeTable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false // Set to true if you want to prevent On-Prem routes from propagating
    routes: [
      {
        name: 'to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0' // Default route
          nextHopType: 'VirtualAppliance' // Required for Firewalls / NVAs
          nextHopIpAddress: nextHopIpAddress
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
