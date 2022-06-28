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

// IotHub
module iothub 'iot-hub.bicep' = {
  name: 'iothub'
  params: {
    longName: longName
  }
}

module storageAccountModule 'storage.bicep' = {
  name: 'storageAccountDeploy'
  params: {
    longName: longName
  }  
}

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = resourceGroup().name
output serviceBusName string = serviceBusModule.outputs.serviceBusName
output serviceBusEndpoint string = serviceBusModule.outputs.serviceBusEndpoint
