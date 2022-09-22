param location string = resourceGroup().location
param envName string
param vehicleRegistrationContainerImage string = 'rutzscolabcr.azurecr.io/dapr-hack/vehicleregistrationservice:latest'
param fineCollectionServiceContainerImage string = 'rutzscolabcr.azurecr.io/dapr-hack/finecollectionservice:latest'
param trafficControlServiceContainerImage string = 'rutzscolabcr.azurecr.io/dapr-hack/trafficcontrolservice:latest'

@secure()
param acrPassword string
param acrUsername string
param acrName string

@secure()
param redisPassword string

@secure()
param servicebusconnectionstring string

@secure()
param logicAppEmailUrl string

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

    lawClientId: law.outputs.clientId
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
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5m'
    secrets: [
      {
        name: 'servicebusconnectionstring'
        value: servicebusconnectionstring
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
  name: '${envName}/sendmail'
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

module vehicleRegistrationService 'aca.bicep' = {
  name: 'vehicleregistrationservice'
  params: {
    name: 'vehicleregistrationservice'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: vehicleRegistrationContainerImage
    envVars: []
    useExternalIngress: true
    containerPort: 6002
    acrPassword: acrPassword
    acrUsername: acrUsername
    acrName: acrName
  }
}

module fineCollectionService 'aca.bicep' = {
  name: 'finecollectionservice'
  params: {
    name: 'finecollectionservice'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: fineCollectionServiceContainerImage
    envVars: []
    useExternalIngress: true
    containerPort: 6001
    acrPassword: acrPassword
    acrUsername: acrUsername
    acrName: acrName
  }
}

module trafficControlService 'aca.bicep' = {
  name: 'trafficcontrolservice'
  params: {
    name: 'trafficcontrolservice'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: trafficControlServiceContainerImage
    envVars: []
    useExternalIngress: true
    containerPort: 6000
    acrPassword: acrPassword
    acrUsername: acrUsername
    acrName: acrName
  }
}

output fqdn string = vehicleRegistrationService.outputs.fqdn
