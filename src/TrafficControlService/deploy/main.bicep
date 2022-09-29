param location string = resourceGroup().location
param containerImage string = 'rutzscolabcr.azurecr.io/dapr-hack/trafficcontrolservice:latest'
param envName string

@secure()
param acrPassword string
param acrUsername string
param acrName string


resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: envName
}

module fineCollectionService 'aca.bicep' = {
  name: 'trafficcontrolservice'
  params: {
    name: 'trafficcontrolservice'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.id
    containerImage: containerImage
    envVars: []
    useExternalIngress: true
    containerPort: 6001
    acrPassword: acrPassword
    acrUsername: acrUsername
    acrName: acrName
  }
}
