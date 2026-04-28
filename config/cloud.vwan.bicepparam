using '../modules/vwan.bicep'

var vTags = {
  Environment: 'Prod'
  SolutionName: 'Hybrid Vwan'
}

param resourceGroupName = 'AVNM-RG'
param tags = vTags

param virtualWanParameters = {
  virtualWanName: 'vwan01'
  tags: vTags
  location: 'canadacentral'
  type: 'Standard'
  allowBranchToBranchTraffic: true
}

// Shared hub properties — referenced in both virtualHubParameters and hubBootstrapConfigs.
var vHUB_CC = {
  name: 'vHUB-CC-Hybrid-Fortinet'
  location: 'canadacentral'
  addressPrefix: '10.58.128.0/21'
  routingPreference: 'ExpressRoute'
}

param virtualHubParameters = [
  {
    hubName: vHUB_CC.name
    hubLocation: vHUB_CC.location
    hubAddressPrefix: vHUB_CC.addressPrefix
    hubRoutingPreference: vHUB_CC.routingPreference
    tags: vTags
    expressRouteParameters: {
      expressRouteGatewayName: 'vHUB-CC-Hybrid-Fortinet-ERGW'
      deployExpressRouteGateway: true
      allowNonVirtualWanTraffic: true
      autoScaleConfigurationBoundsMin: 1
      expressRouteConnections: [
        // {
        //   name: 'er-connection-toVHUBFortinet'
        //   properties: {
        //     // Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/expressRouteCircuits/<circuit>/peerings/AzurePrivatePeering
        //     expressRouteCircuitPeering: {
        //       id: '/subscriptions/e97e7eb7-daad-44e7-823c-9862b6b6eb92/resourceGroups/er-rg/providers/Microsoft.Network/expressRouteCircuits/er-circuit-01/peerings/AzurePrivatePeering'
        //     }
        //     // Do not commit the actual value; inject at deploy time via -TemplateParameterObject or Key Vault.
        //     authorizationKey: ''
        //     enableInternetSecurity: false
        //     routingWeight: 0
        //   }
        // }
      ]
    }
    hubRouteTables: []
  }
]

param hubBootstrapConfigs = [
  {
    hubName: vHUB_CC.name
    hubLocation: vHUB_CC.location
    hubAddressPrefix: vHUB_CC.addressPrefix
    hubRoutingPreference: vHUB_CC.routingPreference
    tags: vTags

    // Min hub router instances — null = platform default.
    routerScaleUnits: 3

    // Route traffic via an external appliance. Set nextHopResourceId and enable flags to activate.
    routingIntent: {
      nextHopResourceId: null  // e.g. '/subscriptions/.../networkVirtualAppliances/nva-fortinet-cc'
      privateTraffic: false
      internetTraffic: false
      additionalPrefixes: []  // e.g. ['100.64.0.0/10'] — appended to PrivateTraffic destinations
    }
  }
]
