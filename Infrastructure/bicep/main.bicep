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

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = resourceGroup().name
output serviceBusName string = serviceBusModule.outputs.serviceBusName
output serviceBusEndpoint string = serviceBusModule.outputs.serviceBusEndpoint
