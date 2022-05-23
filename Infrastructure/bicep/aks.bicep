param longName string
param adminUsername string
param publicSSHKey string
param keyVaultName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'la-${longName}'
  location: resourceGroup().location  
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${longName}'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource aksUserAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'mi-aks-${longName}'
  location: resourceGroup().location
}

resource aksAzurePolicy 'Microsoft.Authorization/policyAssignments@2019-09-01' = {
  name: 'aksAzurePolicy'
  scope: resourceGroup()
  properties: {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/c26596ff-4d70-4e6a-9a30-c2506bd2f80c'
  }  
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: 'aks-${longName}'
  location: resourceGroup().location
  dependsOn: [
    aksAzurePolicy
  ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksUserAssignedManagedIdentity.id}': {}
    }
  }
  properties: {
    kubernetesVersion: '1.19.11'
    dnsPrefix: longName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: publicSSHKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
    }
    podIdentityProfile: {
      enabled: true
      allowNetworkPluginKubenet: true
    }
  }
}

output aksName string = aks.name
output aksfqdn string = aks.properties.fqdn
output aksazurePortalFQDN string = aks.properties.azurePortalFQDN
output aksNodeResourceGroupName string = aks.properties.nodeResourceGroup
output logAnalyticsName string = logAnalytics.name
output aksManagedIdentityName string = aksUserAssignedManagedIdentity.name
output aksManagedIdentityResourceId string = aksUserAssignedManagedIdentity.id
output aksManagedIdentityClientId string = aksUserAssignedManagedIdentity.properties.clientId
output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
