param name string
param location string
param lawClientId string
@secure()
param lawClientSecret string

param logicAppEmailUrl string

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: lawClientId
        sharedKey: lawClientSecret
      }
    }
  }
}

resource redis 'Microsoft.Cache/redis@2022-06-01' existing = { 
  name: 'redis-${name}'
}

resource daprStateStore 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'statestore'
  parent: environment
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secrets: [
      {
        name: 'redispassword'
        value: redis.listKeys().primaryKey
      }
    ]
    metadata: [
      {
        name: 'redisHost'
        value: 'redis-${name}.redis.cache.windows.net:6380'
      }
      {
        name: 'redisPassword'
        secretRef: 'redispassword'
      }
      {
        name: 'actorStateStore'
        value: 'true'
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
    ]
    scopes: [
      'trafficcontrolservice'
    ]
  }
}

resource sb 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' existing = { 
  name: 'sb-${name}'
}

resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'pubsub'
  parent: environment
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secrets: [
      {
        name: 'servicebusconnectionstring'
        value: listKeys(sb.id, sb.apiVersion).primaryConnectionString
      }
    ]
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'servicebusconnectionstring'
      }
    ]
    scopes: [ 'trafficcontrolservice', 'finecollectionservice' ]
  }
}

resource daprLogicAppEmailBinding 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'sendmail'
  parent: environment
  properties: {
    componentType: 'bindings.http'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    metadata: [
      {
        name: 'url'
        value: logicAppEmailUrl
      }
    ]
    scopes: [
      'finecollectionservice'
    ]
  }
}
output id string = environment.id
