// --------------------------------------------------------------------------------
// This BICEP file will create a Logic App
// --------------------------------------------------------------------------------
param name string
param location string = resourceGroup().location
param commonTags object = {}

@description('The workspace to store audit logs.')
param workspaceId string = ''

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~logicapp.bicep' }
var tags = union(commonTags, templateTag)

var connectionName = 'office365'

// --------------------------------------------------------------------------------
resource logicAppConnectionResource 'Microsoft.Web/connections@2016-06-01' = {
    name: connectionName
    location: location
    properties: {
        displayName: 'emailSender@azure.com'
        api: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connectionName}'
        }
    }
}

resource logicAppResource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-smtp-${name}'
  dependsOn: [
      logicAppConnectionResource
  ]
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
        '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
        actions: {
            Parse_JSON: {
                inputs: {
                    content: '@triggerBody()'
                    schema: {
                        properties: {
                            body: {
                                type: 'string'
                            }
                            from: {
                                type: 'string'
                            }
                            subject: {
                                type: 'string'
                            }
                            to: {
                                type: 'string'
                            }
                        }
                        type: 'object'
                    }
                }
                runAfter: {}
                type: 'ParseJson'
            }
            'Send_an_email_(V2)': {
                inputs: {
                    body: {
                        Body: '<p>@{body(\'Parse_JSON\')?[\'body\']}</p>'
                        Subject: '@body(\'Parse_JSON\')?[\'subject\']'
                        To: '@body(\'Parse_JSON\')?[\'to\']'
                    }
                    host: {
                        connection: {
                            name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
                        }
                    }
                    method: 'post'
                    path: '/v2/Mail'
                }
                runAfter: {
                    Parse_JSON: [
                        'Succeeded'
                    ]
                }
                type: 'ApiConnection'
            }
        }
        contentVersion: '1.0.0.0'
        outputs: {}
        parameters: {
            '$connections': {
                defaultValue: {}
                type: 'Object'
            }
        }
        triggers: {
            manual: {
                inputs: {}
                kind: 'Http'
                type: 'Request'
            }
        }
    }
    parameters: {
        '$connections': {
            value: {
                office365: {
                    connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/${connectionName}'                                   
                    connectionName: connectionName
                    id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connectionName}'
                }
            }
        }
    }
}
}

// --------------------------------------------------------------------------------
// resource logicAppAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//     name: '${logicAppResource.name}-auditlogs'
//     scope: logicAppResource
//     properties: {
//       workspaceId: workspaceId
//       logs: [
//         {
//           category: 'allLogs' ---> can't find the right category to put in here...!
//           enabled: true
//           retentionPolicy: {
//             days: 30
//             enabled: true 
//           }
//         }
//       ]
//     }
//   }
  
  resource logicAppMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    name: '${logicAppResource.name}-metrics'
    scope: logicAppResource
    properties: {
      workspaceId: workspaceId
      metrics: [
        {
          category: 'AllMetrics'
          enabled: true
          retentionPolicy: {
            days: 30
            enabled: true 
          }
        }
      ]
    }
  }
  

  
output name string = logicAppResource.name
output accessEndpoint string = logicAppResource.properties.accessEndpoint
output principalId string = logicAppResource.identity.principalId
output tenantId string = logicAppResource.identity.tenantId
