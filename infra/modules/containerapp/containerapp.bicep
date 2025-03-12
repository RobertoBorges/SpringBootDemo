param location string = resourceGroup().location
param containerAppEnvName string
param containerAppName string
param tags object = {}
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' // Default image - will be replaced by your application image
param relativePath string = '<default>'  // Kept for compatibility with existing parameters
param databaseUsername string
@secure()
param databasePassword string
param datasourceUrl string
param port int = 8080
param isExternalIngress bool = true
param minReplicas int = 1
param maxReplicas int = 3
param enableIngress bool = true
param cpu string = '0.5'
param memory string = '1.0Gi'

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  tags: tags
  properties: {
    zoneRedundant: false
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  tags: union(tags, { 'container-app-name': containerAppName })
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: enableIngress ? {
        external: isExternalIngress
        targetPort: port
        transport: 'auto'
        allowInsecure: false
      } : null
    }
    template: {
      containers: [
        {
          image: imageName
          name: containerAppName
          env: [
            {
              name: 'SPRING_DATASOURCE_URL'
              value: datasourceUrl
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: databaseUsername
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              value: databasePassword
            }
          ]
          resources: {
            cpu: json(cpu)
            memory: memory
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output name string = containerApp.name
output uri string = enableIngress ? 'https://${containerApp.properties.configuration.ingress.fqdn}' : ''
