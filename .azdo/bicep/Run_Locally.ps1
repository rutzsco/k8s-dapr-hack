# To deploy this main.bicep manually:
# az login
# az account set --subscription <subscriptionId>

az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'main-infra.bicep' --parameters envName=DEMO orgName=lll-acatc -n manual-main-deploy-20230809T0917Z


# just the Key Vault...
$workspaceId='/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.OperationalInsights/workspaces/lll-acatc-logworkspace-demo '
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvault.bicep' --parameters  keyVaultName=lllacatcvaultdemo location=eastus enabledForDeployment=true enabledForTemplateDeployment=true enabledForDiskEncryption=true enableSoftDelete=false enablePurgeProtection=true softDeleteRetentionInDays=7 useRBAC=false publicNetworkAccess=Enabled allowNetworkAccess=Allow createUserAssignedIdentity=true createDaprIdentity=true workspaceId=$workspaceId -n manual-keyvault-deploy-20230809T1556Z 

# just the Key Vault App Rights...
$appPrincipalId='74340fa6-b7f1-4f47-ba7f-936cbe0d4be5' # trafficcontrolservice managed identity
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultadminrights.bicep' --parameters keyVaultName=lllacatcvaultdemo onePrincipalId=$appPrincipalId -n manual-keyvault-rights-deploy-20230809T0939Z
$appPrincipalId='4566383e-9c66-468c-893f-4c4997d0cb2d' # finecollectionservice managed identity
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultadminrights.bicep' --parameters keyVaultName=lllacatcvaultdemo onePrincipalId=$appPrincipalId -n manual-keyvault-rights-deploy-20230809T0939Z 
$appPrincipalId='d63d1e3e-c734-40c0-8489-cc45e859112d' # vehicleregistrationservice managed identity
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultadminrights.bicep' --parameters keyVaultName=lllacatcvaultdemo onePrincipalId=$appPrincipalId -n manual-keyvault-rights-deploy-20230809T0939Z 
$appPrincipalId='94bbac1f-f33d-4e82-a684-c27bd78ffcd1' # logic app managed identity
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultadminrights.bicep' --parameters keyVaultName=lllacatcvaultdemo onePrincipalId=$appPrincipalId -n manual-keyvault-rights-deploy-20230809T0939Z 
$appPrincipalId='adc5a081-2686-4024-9d7d-43a7a6346c90' # unknown service...?
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultadminrights.bicep' --parameters keyVaultName=lllacatcvaultdemo onePrincipalId=$appPrincipalId -n manual-keyvault-rights-deploy-20230809T0939Z 

$appName='trafficcontrolservice'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultcontainerapprights.bicep' --parameters keyVaultName=lllacatcvaultdemo containerAppName=$appName -n manual-keyvault-rights-deploy-20230809T0939Z
$appName='vehicleregistrationservice'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultcontainerapprights.bicep' --parameters keyVaultName=lllacatcvaultdemo containerAppName=$appName -n manual-keyvault-rights-deploy-20230809T0939Z


# just the IotHub...
$workspaceId='/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.OperationalInsights/workspaces/lll-iot-logworkspace-demo '
$deploymentName='manual-iothub-deploy-20230727T1530Z'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'iothub.bicep' --parameters iotHubName=lll-iot-hub-demo iotStorageAccountName=llliotdemohub iotStorageContainerName=iothubuploads location=eastus sku=S1 allowStorageNetworkAccess=Allow serviceBusName=lll-iot-svcbus-demo workspaceId=$workspaceId -n $deploymentName

# just the redisCache...
$workspaceId='/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.OperationalInsights/workspaces/lll-acatc-logworkspace-demo'
$deploymentName='manual-redisCache-deploy-20230804T704Z'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'redisCache.bicep' --parameters name=lll-acatc-redis-demo location=eastus workspaceId=$workspaceId -n $deploymentName

# just the redisCache.KeyVault...
$deploymentName='manual-redisCacheKeyVault-deploy-20230807T1556Z'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'keyvaultsecretrediscacheconnection.bicep' --parameters keyVaultName=lllacatcvaultdemo secretNameKey=redisKey secretNameConnection=redisConnectionString redisCacheName=lll-acatc-redis-demo  -n $deploymentName

# just the logicApp...
$workspaceId='/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.OperationalInsights/workspaces/lll-acatc-logworkspace-demo'
$deploymentName='manual-logicApp-deploy-20230804T704Z'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'logicApp.bicep' --parameters name=lll-acatc-la-demo location=eastus workspaceId=$workspaceId -n $deploymentName


# just the Service Bus...
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'servicebus.bicep' --parameters serviceBusName=lll-iot-svcbus-demo location=eastus workspaceId=/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.OperationalInsights/workspaces/lll-iot-logworkspace-demo  -n manual-streaming-deploy-20230724T1111Z

# just the Container App Environment...
$workspaceId='/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.OperationalInsights/workspaces/lll-acatc-logworkspace-demo '
$deploymentName='manual-containerenv-deploy-20230809T1533Z'
az deployment group create --resource-group rg-traffic-control-aca-demo --template-file 'acaEnvironment.bicep' --parameters name=lll-acatc-acae-demo location=eastus logAnalyticsName=lll-acatc-logworkspace-demo logicAppEndpoint=https://prod-44.eastus.logic.azure.com:443/workflows/1b812799099149b29f2d8ff0867a27e6 appInsightsName=lll-acatc-insights-demo redisName=lll-acatc-redis-demo keyVaultName=lllacatcvaultdemo keyVaultPrincipalId=/subscriptions/a0f86c93-146a-4534-b83e-49090394aa78/resourceGroups/rg-traffic-control-aca-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/lllacatcvaultdemo-cicd workspaceId=$workspaceId -n $deploymentName

# logic app
# mqtt
# redis
# storage
