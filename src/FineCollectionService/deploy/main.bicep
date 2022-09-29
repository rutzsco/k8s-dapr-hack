param location string = resourceGroup().location
param fineCollectionServiceContainerImage string = 'rutzscolabcr.azurecr.io/dapr-hack/finecollectionservice:latest'
param envName string

@secure()
param acrPassword string
param acrUsername string
param acrName string


resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: envName
}

module fineCollectionService 'aca.bicep' = {
  name: 'finecollectionservice'
  params: {
    name: 'finecollectionservice'
    location: location
    containerAppEnvironmentId: containerAppEnvironment.id
    containerImage: fineCollectionServiceContainerImage
    envVars: []
    useExternalIngress: true
    containerPort: 6001
    acrPassword: acrPassword
    acrUsername: acrUsername
    acrName: acrName
  }
}
