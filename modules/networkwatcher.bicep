@description('Location for all resources.')
param location string = resourceGroup().location

resource networkWatcher 'Microsoft.Network/networkWatchers@2023-04-01' = {
  name: 'NetworkWatcher_${location}'
  location: location
  properties: {}
}
