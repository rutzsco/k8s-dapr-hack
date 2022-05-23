param longName string

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: 'ehn-${longName}-trafficcontrol'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
}

var eventHubEntryCamName = 'entrycam'

resource eventHubEntryCam 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {
  name: '${eventHubNamespace.name}/${eventHubEntryCamName}'
  dependsOn: [
    eventHubNamespace
  ]
  properties: {
    partitionCount: 1
    messageRetentionInDays: 1
  }
}

resource eventHubEntryCamConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-01-01-preview' = {
  name: '${eventHubNamespace.name}/${eventHubEntryCamName}/trafficcontrolservice'
  dependsOn: [
    eventHubEntryCam
  ]
}

resource eventHubEntryCamListenAuthorizationRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  name: '${eventHubEntryCam.name}/listen'
  dependsOn: [
    eventHubEntryCam
  ]
  properties: {
    rights: [
      'Listen'
    ]
  }
}

var eventHubExitCamName = 'exitcam'

resource eventHubExitCam 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {
  name: '${eventHubNamespace.name}/${eventHubExitCamName}'
  dependsOn: [
    eventHubNamespace
  ]
  properties: {
    partitionCount: 1
    messageRetentionInDays: 1
  }
}

resource eventHubExitCamConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2021-01-01-preview' = {
  name: '${eventHubNamespace.name}/${eventHubExitCamName}/trafficcontrolservice'
  dependsOn: [
    eventHubExitCam
  ]
}

resource eventHubExitCamListenAuthorizationRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = {
  name: '${eventHubExitCam.name}/listen'
  dependsOn: [
    eventHubExitCam
  ]
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource iotHubUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'id-iotHub-${longName}'
  location: resourceGroup().location
}

resource iotHubUserEventHubEntryCamEventHubDataSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id, iotHubUserAssignedIdentity.name, 'entrycam')
  properties: {
    principalId: iotHubUserAssignedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId(subscription().subscriptionId, 'Microsoft.Authorization/roleDefinitions', '2b629674-e913-4c01-ae53-ef4638d8f975')
  }
  scope: eventHubEntryCam
}

resource iotHubUserEventHubExitCamEventHubDataSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(resourceGroup().id, iotHubUserAssignedIdentity.name, 'exitcam')
  properties: {
    principalId: iotHubUserAssignedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId(subscription().subscriptionId, 'Microsoft.Authorization/roleDefinitions', '2b629674-e913-4c01-ae53-ef4638d8f975')  
  }
  scope: eventHubExitCam
}

var eventHubNamespaceEndpointUri = 'sb://${eventHubNamespace.name}.servicebus.windows.net'

resource iotHub 'Microsoft.Devices/IotHubs@2021-03-31' = {
  name: 'iothub-${longName}'
  location: resourceGroup().location
  sku: {
    name: 'B1'
    capacity: 1
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${iotHubUserAssignedIdentity.id}': {}
    }
  }
  properties: {
    //minTlsVersion: '1.2'
    routing: {
      endpoints: {
        eventHubs: [
          {
            name: 'entrycam'
            authenticationType: 'identityBased'
            identity: {
              userAssignedIdentity: iotHubUserAssignedIdentity.id
            }
            endpointUri: eventHubNamespaceEndpointUri
            entityPath: eventHubEntryCamName
            subscriptionId: subscription().subscriptionId
            resourceGroup: resourceGroup().name
          }
          {
            name: 'exitcam'
            authenticationType: 'identityBased'
            identity: {
              userAssignedIdentity: iotHubUserAssignedIdentity.id
            }
            endpointUri: eventHubNamespaceEndpointUri
            entityPath: eventHubExitCamName
            subscriptionId: subscription().subscriptionId
            resourceGroup: resourceGroup().name
          }
        ]
      }
      routes: [
        {
          name: 'entrycam'
          source: 'DeviceMessages'
          condition: 'trafficcontrol = \'entrycam\''
          endpointNames: [
            eventHubEntryCamName
          ]
          isEnabled: true
        }
        {
          name: 'exitcam'
          source: 'DeviceMessages'
          condition: 'trafficcontrol = \'exitcam\''
          endpointNames: [
            eventHubExitCamName
          ]
          isEnabled: true
        }
      ]
    }
  }
  dependsOn: [
    iotHubUserEventHubEntryCamEventHubDataSenderRoleAssignment
    iotHubUserEventHubExitCamEventHubDataSenderRoleAssignment
  ]
}

output iotHubName string = iotHub.name
output eventHubNamespaceName string = eventHubNamespace.name
output eventHubNamespaceHostName string = eventHubNamespace.properties.serviceBusEndpoint
output eventHubNamespaceEndpointUri string = eventHubNamespaceEndpointUri
output eventHubEntryCamName string = eventHubEntryCam.name
output eventHubExitCamName string = eventHubExitCam.name
