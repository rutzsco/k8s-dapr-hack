param appName string
param environment string

var longName = '${appName}-${environment}'

module serviceBusModule 'serviceBus.bicep' = {
  name: 'serviceBusDeploy'
  params: {
    longName: longName
  }
}

module redisCacheModule 'redisCache.bicep' = {
  name: 'redisCacheDeploy'
  params: {
    longName: longName
  }  
}

module logicAppModule 'logicApp.bicep' = {
  name: 'logicAppDeploy'
  params: {
    longName: longName
  }  
}

module mqttModule 'mqtt.bicep' = {
  name: 'mqttDeploy'
  params: {
    longName: longName
  }  
}

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = resourceGroup().name
output serviceBusName string = serviceBusModule.outputs.serviceBusName
output serviceBusEndpoint string = serviceBusModule.outputs.serviceBusEndpoint
