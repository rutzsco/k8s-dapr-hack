// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param orgName string = ''
@allowed(['azd','gha','azdo','dev','demo','qa','stg','ct','prod'])
param environmentName string = 'demo'

// --------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentName)
var sanitizedOrgNameWithDashes = replace(replace(toLower(orgName), ' ', ''), '_', '')
var sanitizedOrgName = replace(replace(replace(toLower(orgName), ' ', ''), '-', ''), '_', '')

// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('resourceabbreviations.json')

// --------------------------------------------------------------------------------
output logAnalyticsWorkspaceName string   = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.logworkspace}-${sanitizedEnvironment}')
output acaEnvironmentName string          = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.containerAppsEnvironment}-${sanitizedEnvironment}')
output redisName string                   = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.redis}-${sanitizedEnvironment}')
output serviceBusName string              = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.serviceBus}-${sanitizedEnvironment}')
output logicAppName string                = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.logicApp}-${sanitizedEnvironment}')
output cosmosName string                  = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.cosmosDb}-${sanitizedEnvironment}')
output iotHubName string                  = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.iotHub}-${sanitizedEnvironment}')
output appInsightsName string             = toLower('${sanitizedOrgNameWithDashes}-${resourceAbbreviations.appInsightsSuffix}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
// Container names can only be alpha
output containerRegistryName string       = toLower('${sanitizedOrgName}${resourceAbbreviations.containerRegistry}${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
// Key Vaults and Storage Accounts can only be 24 characters long
output keyVaultName string                = take('${sanitizedOrgName}${resourceAbbreviations.keyVaultAbbreviation}${sanitizedEnvironment}', 24)
output storageAccountName string          = take('${sanitizedOrgName}${resourceAbbreviations.storageAccountSuffix}data${sanitizedEnvironment}', 24)
output iotStorageAccountName string       = take('${sanitizedOrgName}${resourceAbbreviations.storageAccountSuffix}iot${sanitizedEnvironment}', 24)
output logicAppStorageAccountName string  = take('${sanitizedOrgName}${resourceAbbreviations.storageAccountSuffix}logic${sanitizedEnvironment}', 24)
