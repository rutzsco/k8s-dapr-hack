@description('Unique name for the Azure Container Registry instance')
param p_acrName string = 'acr${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: p_acrName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  
}
