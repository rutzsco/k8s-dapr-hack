param appName string
param environment string

var longName = '${environment}-${appName}'

module serviceBusModule 'serviceBus.bicep' = {
  name: 'serviceBusDeploy'
  params: {
    longName: longName
  }
}

output subscriptionId string = subscription().subscriptionId
output resourceGroupName string = resourceGroup().name
output serviceBusName string = serviceBusModule.outputs.serviceBusName
output serviceBusEndpoint string = serviceBusModule.outputs.serviceBusEndpoint
