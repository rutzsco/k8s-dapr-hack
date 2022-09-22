param location string = resourceGroup().location
param envName string
param appName string
param containerImage string
param containerPort int = 80
@secure()
param acrPassword string
param acrUsername string
param acrName string

@secure()
param redisPassword string

@secure()
param servicebusconnectionstring string

module law 'log-analytics.bicep' = {
	name: 'log-analytics-workspace'
	params: {
      location: location
      name: 'law-${envName}'
	}
}

module containerAppEnvironment 'aca-environment.bicep' = {
  name: 'container-app-environment'
  params: {
    name: envName
    location: location
    
    lawClientId:law.outputs.clientId
    lawClientSecret: law.outputs.clientSecret
  }
}

resource daprStateStore 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${envName}/statestore'
  properties: {
      componentType: 'state.redis'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5m'
      secrets: [
          {
              name: 'redispassword'
              value: redisPassword
          }
      ]
      metadata: [
          {
              name: 'redisHost'
              value: 'redis-rutzsco-dapr-demo-ci.redis.cache.windows.net:6380'
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

resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: '${envName}/pubsub'
  properties: {
      componentType: 'statestore'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5m'
      secrets: [
          {
              name: 'connectionString'
              value: servicebusconnectionstring
          }
      ]
      metadata: [
          {
              name: 'connectionString'
              secretRef: 'servicebusconnectionstring'
          }
      ]
  }
}

module containerApp 'aca.bicep' = {
  name: appName
  params: {
    name: appName
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: containerImage
    envVars: []
    useExternalIngress: true
    containerPort: containerPort
    acrPassword: acrPassword
    acrUsername: acrUsername
    acrName: acrName
  }
}

output fqdn string = containerApp.outputs.fqdn
