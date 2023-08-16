// ------------------------------------------------------------------------------------------------------------------------
// Main Bicep File for Azure Container App Project
// ------------------------------------------------------------------------------------------------------------------------
param orgName string = ''
param envName string = 'DEMO'
param runDateTime string = utcNow()
param location string = resourceGroup().location

// ------------------------------------------------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  LastDeployed: runDateTime
  Organization: orgName
  Environment: envName
}

// --------------------------------------------------------------------------------
module resourceNames 'resourcenames.bicep' = {
  name: 'resourceNames${deploymentSuffix}'
  params: {
    orgName: orgName
    environmentName: toLower(envName)
  }
}

// ------------------------------------------------------------------------------------------------------------------------
module containerRegistryModule 'containerregistry.bicep' = {
  name: 'containerRegistry${deploymentSuffix}'
  params: {
    containerRegistryName: resourceNames.outputs.containerRegistryName
    location: location
    skuName: 'Premium'
    commonTags: commonTags
  }
}

module logAnalyticsModule 'loganalytics.bicep' = {
  name: 'logAnalyticsWorkspace${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.logAnalyticsWorkspaceName
    location: location
    commonTags: commonTags
  }
}

module serviceBusModule 'servicebus.bicep' = {
  name: 'serviceBus${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.serviceBusName
    topicNames: [ 'collectfine' ] 
    queueNames: []
    location: location
    commonTags: commonTags
    workspaceId: logAnalyticsModule.outputs.id
  }
}

module redisCacheModule 'rediscache.bicep' = {
  name: 'redisCache${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.redisName
    location: location
    commonTags: commonTags
    workspaceId: logAnalyticsModule.outputs.id
  }  
}

module logicAppModule 'logicapp.bicep' = {
  name: 'logicApp${deploymentSuffix}'
  params: {
    name: resourceNames.outputs.logicAppName
    location: location
    commonTags: commonTags
    workspaceId: logAnalyticsModule.outputs.id
  }  
}

// what is the right container name for cosmos for this app...?
var cosmosContainerArray = [
  { name: 'MyContainer', partitionKey: '/partitionKey' }
]
module cosmosModule 'cosmosdatabase.bicep' = {
  name: 'cosmos${deploymentSuffix}'
  params: {
    cosmosAccountName: resourceNames.outputs.cosmosName 
    location: location
    containerArray: cosmosContainerArray
    cosmosDatabaseName: 'MyDatabase'
    commonTags: commonTags
    //workspaceId: logAnalyticsModule.outputs.id --> need to define metrics logging!, need to enable Diagnostic full-text query first...!
  }
}

// module iotHubModule 'iothub.bicep' = {
//   name: 'iotHub${deploymentSuffix}'
//   params: {
//     iotHubName: resourceNames.outputs.iotHubName
//     iotStorageAccountName: resourceNames.outputs.iotStorageAccountName
//     iotStorageContainerName: 'iothubuploads'
//     location: location
//     commonTags: commonTags
//     workspaceId: logAnalyticsModule.outputs.id
//   }
// }

module keyVaultModule 'keyvault.bicep' = {
  name: 'keyVault-Deploy${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    location: location
    commonTags: commonTags
    workspaceId: logAnalyticsModule.outputs.id
  }
}
module keyVaultAppRightsModule 'keyvaultadminrights.bicep' = {
  name: 'keyVault-Rights${deploymentSuffix}'
  params: {
    keyVaultName: keyVaultModule.outputs.name
    onePrincipalId: logicAppModule.outputs.principalId
    onePrincipalAdminRights: false
    onePrincipalCertificateRights: false
  }
}

module keyVaultSecretList 'keyvaultlistsecretnames.bicep' = {
  name: 'keyVault-SecretsList${deploymentSuffix}'
  dependsOn: [ keyVaultModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    location: location
    userManagedIdentityId: keyVaultModule.outputs.userManagedIdentityId
  }
}
module keyVaultSecretCosmos 'keyvaultsecretcosmosconnection.bicep' = {
  name: 'keyVaultSecret-Cosmos${deploymentSuffix}'
  dependsOn: [ keyVaultModule, cosmosModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'cosmosConnectionString'
    cosmosAccountName: cosmosModule.outputs.name
    existingSecretNames: keyVaultSecretList.outputs.secretNameList
  }
}
// module keyVaultSecretIoTHub 'keyvaultsecretiothubconnection.bicep' = {
//   name: 'keyVaultSecret-IoTHub${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, iotHubModule ]
//   params: {
//     keyVaultName: keyVaultModule.outputs.name
//     secretName: 'iotHubConnectionString'
//     iotHubName: iotHubModule.outputs.name
//     existingSecretNames: keyVaultSecretList.outputs.secretNameList
//   }
// }
// module keyVaultSecretIoTStorage 'keyvaultsecretstorageconnection.bicep' = {
//   name: 'keyVaultSecret-IoTStorage${deploymentSuffix}'
//   dependsOn: [ keyVaultModule, iotHubModule ]
//   params: {
//     keyVaultName: keyVaultModule.outputs.name
//     secretName: 'iotStorageAccountConnectionString'
//     storageAccountName: iotHubModule.outputs.storageAccountName
//     existingSecretNames: keyVaultSecretList.outputs.secretNameList
//   }
// }
module keyVaultSecretSvcBus 'keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret-SvcBus${deploymentSuffix}'
  dependsOn: [ keyVaultModule, serviceBusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretName: 'servicebusconnectionstring'
    serviceBusName: serviceBusModule.outputs.name
    existingSecretNames: keyVaultSecretList.outputs.secretNameList
  }
}

module keyVaultSecretRedis 'keyvaultsecretrediscacheconnection.bicep' = {
  name: 'keyVaultSecret-Redis${deploymentSuffix}'
  dependsOn: [ keyVaultModule, redisCacheModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    secretNameKey: 'redispassword'
    secretNameConnection: 'redisConnectionString'
    redisCacheName: redisCacheModule.outputs.name
    existingSecretNames: keyVaultSecretList.outputs.secretNameList
  }
}

module acaEnvironmentResource 'acaenvironment.bicep' = {
  name: 'containerAppEnvironment${deploymentSuffix}'
  dependsOn: [ keyVaultSecretRedis, keyVaultSecretSvcBus ]
  params: {
    name: resourceNames.outputs.acaEnvironmentName
    location: location
    serviceBusName: serviceBusModule.outputs.name
    logAnalyticsName: logAnalyticsModule.outputs.name
    logicAppEndpoint: logicAppModule.outputs.accessEndpoint
    redisName: redisCacheModule.outputs.name
    appInsightsName: resourceNames.outputs.appInsightsName
    keyVaultName: resourceNames.outputs.keyVaultName
    keyVaultPrincipalId: keyVaultModule.outputs.daprIdentityId
    workspaceId: logAnalyticsModule.outputs.id
    commonTags: commonTags
  }
}
