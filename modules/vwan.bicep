targetScope = 'subscription'

param virtualWanParameters object
param tags object
param virtualHubParameters array
param resourceGroupName string
param resourceGroupLocation string = 'canadacentral'
param hubBootstrapConfigs array = []

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: tags
}

module vwan 'br/public:avm/ptn/network/virtual-wan:0.1.0' = {
  name: 'vwan-deployment'
  scope: rg
  params: {
    virtualWanParameters: virtualWanParameters
    virtualHubParameters: virtualHubParameters
  }
}

module bootstrap './vwan-bootstrap.bicep' = if (!empty(hubBootstrapConfigs)) {
  name: 'bootstrap-deployment'
  scope: rg
  dependsOn: [vwan]
  params: {
    vwanName: virtualWanParameters.virtualWanName
    hubBootstrapConfigs: hubBootstrapConfigs
  }
}
