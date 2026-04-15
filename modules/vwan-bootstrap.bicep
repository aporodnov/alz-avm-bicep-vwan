param vwanName string
param hubBootstrapConfigs array

resource vwan 'Microsoft.Network/virtualWans@2024-05-01' existing = {
  name: vwanName
}

// Hub properties (location, addressPrefix, hubRoutingPreference) are driven by the shared
// vHUB_CC variable in baseline.bicepparam — mismatches are structurally prevented.
module hubUpdate 'br/public:avm/res/network/virtual-hub:0.4.3' = [
  for config in hubBootstrapConfigs: {
    name: 'hub-update-${config.hubName}'
    params: {
      name: config.hubName
      location: config.hubLocation
      addressPrefix: config.hubAddressPrefix
      virtualWanResourceId: vwan.id
      hubRoutingPreference: config.?hubRoutingPreference
      // null leaves router scale at platform default
      virtualRouterAutoScaleConfiguration: config.?routerScaleUnits != null ? {
        minCount: config.routerScaleUnits
      } : null
    }
  }
]

// Routing intent — only deployed when nextHopResourceId is set and at least one traffic flag is true.
resource routingIntent 'Microsoft.Network/virtualHubs/routingIntent@2024-05-01' = [
  for (config, i) in hubBootstrapConfigs: if (config.?routingIntent.?nextHopResourceId != null && (config.?routingIntent.?privateTraffic == true || config.?routingIntent.?internetTraffic == true)) {
    name: '${config.hubName}/RoutingIntent'
    dependsOn: [
      hubUpdate[i]
    ]
    properties: {
      routingPolicies: concat(
        config.?routingIntent.?privateTraffic == true ? [
          {
            name: 'PrivateTrafficPolicy'
            destinations: concat([ 'PrivateTraffic' ], config.?routingIntent.?additionalPrefixes ?? [])
            nextHop: config.routingIntent.nextHopResourceId
          }
        ] : [],
        config.?routingIntent.?internetTraffic == true ? [
          {
            name: 'InternetTrafficPolicy'
            destinations: [ 'Internet' ]
            nextHop: config.routingIntent.nextHopResourceId
          }
        ] : []
      )
    }
  }
]
