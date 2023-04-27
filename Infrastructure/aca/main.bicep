param location string = resourceGroup().location
param envName string
param vehicleRegistrationContainerImage string = 'rutzscolabcr.azurecr.io/dapr-traffic-control/vehicleregistrationservice:latest'
param fineCollectionServiceContainerImage string = 'rutzscolabcr.azurecr.io/dapr-traffic-control/finecollectionservice:latest'
param trafficControlServiceContainerImage string = 'rutzscolabcr.azurecr.io/dapr-traffic-control/trafficcontrolservice:latest'

@secure()
param acrPassword string
param acrUsername string
param acrName string

@secure()
param logicAppEmailUrl string

module law 'log-analytics.bicep' = {
  name: 'log-analytics-workspace'
  params: {
    location: location
    name: 'law-${envName}'
  }
}

module environment 'aca-environment.bicep' = {
  name: 'container-app-environment'
  params: {
    name: envName
    location: location

    lawClientId: law.outputs.clientId
    lawClientSecret: law.outputs.clientSecret
    logicAppEmailUrl: logicAppEmailUrl
  }
}

module vehicleRegistrationService 'aca.bicep' = {
  name: 'vehicleregistrationservice'
  params: {
    name: 'vehicleregistrationservice'
    location: location
    containerAppEnvironmentId: environment.outputs.id
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
    containerAppEnvironmentId: environment.outputs.id
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
    containerAppEnvironmentId: environment.outputs.id
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
