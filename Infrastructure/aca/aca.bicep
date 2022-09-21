param location string
param name string
param containerAppEnvironmentId string

// Container Image ref
param containerImage string

// Networking
param useExternalIngress bool = false
param containerPort int

param envVars array = []

param acrName string
param acrUsername string
@secure()
param acrPassword string

var containerImageParts = split(containerImage, ':')

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: name
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {  
      secrets: [
        {
            name: 'acrpassword'
            value: acrPassword
        }
    ]
    registries: [
        {
            server: '${acrName}.azurecr.io'
            username: acrUsername
            passwordSecretRef: 'acrpassword'
        }
    ]
      ingress: {
        external: useExternalIngress
        targetPort: containerPort
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: name
          env: [
            {
                name: 'APPLICATION_VERSION'
                value: containerImageParts[1]
            }
        ]
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
