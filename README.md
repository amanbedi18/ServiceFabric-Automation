# ServiceFabric-Automation
Automation PowerShell scripts and ARM templates for Service Fabric

## Provision necessary components like Key vault, self signed certificate, AD apps for cluster authentication & Azure service fabric cluster with load balancer, virtual network, Virtual machine scale sets, storage accounts for storing VHD's, diagnostic / ETW logs and key vault resources.

1. Deploy Key vault via the ARM template : Service-Fabric\KeyVaultResourceGroup\KeyVault.json.(Would be required to provide object ID's of various AD groups with different permissions to access/modify keys and secrets in the key vault, customize as per requirements in the template).

2. Execute Service-Fabric\KeyVaultResourceGroup\Scripts\KeyVault\New-ServiceFabricClusterCertificate.ps1 with the following arguments:

* Password = password for the certificate
* CertDNSName = service fabric DNS name i.e. {your service fabric cluster name}.{region of cluster deployment}.cloudapp.azure.com

3. Copy the thumbprint and import the certificate in user's Personal certificate store. (Use the password which was configured).

4. Execute Service-Fabric\KeyVaultResourceGroup\Deploy-Dev1.ps1 with following arguments:

* ASFClusterName, ASFServiceName = cluster name
* ASFLocation = Location of the service fabric cluster
* KeyVaultName = Name of the previously deployed keyvault
* KeyVaultASFClusterCertificateSecretName = Name of the previously created ASF Certificate
* KeyVaultASFClusterCertificatePassword = Password of the previously created ASF Certificate
* userName = admin, service principal user name of azure subscriptions's co-owner
* password = admin, service principal password of azure subscription's co-owner
* subscriptionName = Name of the azure subscription for silent authentication

This script will upload the certificate to the key vault and create 2 applications in the active directory:
1. A native application for native clients like Visual Studio, PowerShell etc, to connect with Azure Service Fabric.
2. A web application which would re-direct to cluster explorer of the Azure service fabric after successful authentication against the AD.

5. Deploy Azure Service Fabric Cluster via the ARM template : Service-Fabric\ASFResourceGroup\ServiceFabricCluster.json

The parameter file requires arguments like : 
* certificateThumbprint = the thumbprint of the certificate (generated as output of New-ServiceFabricClusterCertificate.ps1)
* sourceVaultResourceId = the key vault resource ID for the accessing the uploaded certificate by the cluster (generated as output of Deploy-Dev1.ps1)
* certificateUrlValue = the URL to certificate secret stored in key vault, to help the nodes of the cluster import the same for establishing trust (generated as output of Deploy-Dev1.ps1)
* aadTenantId = tenant ID of the default AAD for authenticating users to access cluster explorer (generated as output of Deploy-Dev1.ps1)
* aadClusterApplicationId = application ID of web applicaiton for authentication (generated as output of Deploy-Dev1.ps1)
* aadClientApplicationId = application ID of client applicaiton for authentication (generated as output of Deploy-Dev1.ps1)

_**NOTE: Enter as many storage account names as the number of node types in the array vmNodeTypeStorageAccountNames in parameters file. Also the elements in vmNodeTypeSkuNames should equal the number of node types to define node type SKU's for all the nodes in the respective node types.**_

## To increase node type count / increase or decrease node count for each node type for the cluster make the following changes in the ARM template : 

### Necessary parameter changes in the ARM template:

1. Increase the count of the array clusterNodeTypePrimary to match the node type count and assign the positional values corresponding to the desired primary node type (the one to host service fabric default servies) to be true. (Usually the first node type and hence the element at index 0 is true and rest all are false).

2. Increase the count of the array clusterNodeTypeDurability to match node type count and assign positional values corresponding to desired durability level of each node type.

3. Increase the count of the array clusterNodeTypeReliability to match node type count and assign positional values corresponding to desired reliability level of each node type.

4. Increase the count of the array vmNodeTypeNames to match node type count and assign positional values corresponding to desired name of each node type.

5. Increase the count of the array vmNodeTypeSkuCapacity to match node type count and assign positional values corresponding to desired count of nodes for each node type.

6. Increase the count of the array vmNodeTypeSkuTiers to match node type count and assign positional values corresponding to desired node type SKU teir for each node type.

7. Increase the count of the array vmNodeTypeStorageAccountNames to match node type count and assign positional values corresponding to desired node type storage account name for each node type to store the VHD's of all the nodes in the given node type.

8. Increase the count of the array vmNodeTypeStorageAccountTypes to match node type count and assign positional values corresponding to desired node type storage account type for each node type.

9. Increase the count of the array vmNodeTypeStorageAccountTypes to match node type count and assign positional values corresponding to desired node type storage account type for each node type.

10. Increase the count of the array supportLogStorageAccountType to match node type count and assign positional values corresponding to desired node type storage account type for support logs storage accounts of each node type.

11. Increase the count of the array diagnosticsStorageAccountType to match node type count and assign positional values corresponding to desired node type storage account type for diagnostic logs storage accounts of each node type.

12. Increase the count of the array vmNodeTypeSubnetNames to match node type count and assign positional values corresponding to subnet name for each node type.

13. Increase the count of the array vmNodeTypeSubnetPrefixes to match node type count and assign positional values corresponding to subnet range for each node type. (Ensure to reserve enough CIDR addresses in addressprefix parameter).

14. Add / remove elements in vmNodeTypeLBNames array to assign public load balancer names based on the count of node types that are public facing.

15. Add / remove elements in vmNodeTypeLBIPNames array to assign public IP's for public facing load balancer. The element count should equal that of the vmNodeTypeLBNames array.

16. Add / remove elements in vmNodeTypeLBIPAllocationMethods array to assign public IP's allocation method for public facing load balancer. The element count should equal that of the vmNodeTypeLBNames array.

17. Add / remove elements in vmNodeTypeInternalLBNames array to assign internal load balancer names based on the count of node types that are internal facing.

18. Add / remove elements in vmNodeTypeInternalLBIPAddresses array to assign static internal IP's for internal load balancer. The element count should equal that of the vmNodeTypeInternalLBNames array.(Ensure to reserve enough CIDR addresses in addressprefix parameter).

19. Increase the count of the array vmNodeTypePlacementRules to match node type count and assign positional values corresponding to desired placement constraints for services that would reside in respective node type. 

### Necessary Variable Changes in the ARM Template:

1. Add variables 
vmNodeType{Node type index}SubnetName: "[parameters('vmNodeTypeSubnetNames')[{Node type subnetindex}]]",
vmNodeType{Node type index}SubnetPrefix = "[parameters('vmNodeTypeSubnetPrefixes')[{Node type subnetindex}]]"
This will map the subnet names and subnet prefix for given node type. Add as many declarations as the new node types and the final count of each variable type should equal that of the node types and the number of elements in the array vmNodeTypeSubnetNames.

2. Add elements to the array subnetRef as:
[concat(variables('vnetID'), '/subnets/', parameters('vmNodeTypeSubnetNames')[{Subnet name index}])]
This will map the subnet resource reference for given node type. Add as many declarations as the new node types and the final count of the elements in this array should equal that of the node types and the number of elements in the array vmNodeTypeSubnetNames.

3. Add elements to the array lbID as:
[resourceId('Microsoft.Network/loadBalancers', parameters('vmNodeTypeLBNames')[{Load balancer index}])]
This will map the load balancer resource reference for given node type. Add as many declarations as the new node types and the final count of the elements in this array should equal the sum of public and internal load balancer count i.e. the sum of the counts of arrays vmNodeTypeLBNames and vmNodeTypeInternalLBNames. Use positional parameters for vmNodeTypeLBNames (public load balancers) followed by vmNodeTypeInternalLBNames (internal load balancers) as convention for correctly configuring the load balancer resource ID's and in turn the rest of the mappings.

4. Add elements to the array lbIPConfig as:
[concat(variables('lbID')[{Load balancer ID index}], '/frontendIPConfigurations/LoadBalancerIPConfig')]
This will map the load balancer frontend IP configuration for given node type. Add as many declarations as the new node types and the final  count of the elements in this array should equal that of lbID array.

5. Add elements to the array lbPoolID as:
[concat(variables('lbID')[{Load balancer ID index}], '/backendAddressPools/LoadBalancerBEAddressPool')]
This will map the load balancer backend address pool for given node type. Add as many declarations as the new node types and the final count of the elements in this array should equal that of lbID array.

6. Add elements to the array lbProbeID as:
[concat(variables('lbID')[{Load balancer ID index}], '/probes/FabricGatewayProbe')]
This will map the load balancer probes for given node type. Add as many declarations as the new node types and the final count of the elements in this array should equal that of lbID array.

7. Add elements to the array lbHttpProbeID as:
[concat(variables('lbID')[{Load balancer ID index}], '/probes/FabricHttpGatewayProbe')]
This will map the load balancer http probe for given node type. Add as many declarations as the new node types and the final count of the elements in this array should equal that of lbID array.

8. Add elements to the array lbNatPoolID as:
[concat(variables('lbID')[{Load balancer ID index}], '/inboundNatPools/LoadBalancerBEAddressNatPool')]
This will map the load balancer NAT pool ID for given node type. Add as many declarations as the new node types and the final count of the elements in this array should equal that of lbID array.

### Necessary Resource Changes in the ARM Template:

1. Add as many storage accounts as the count of the node types.

 {
      "apiVersion": "2015-06-15",
      "type": "Microsoft.Storage/storageAccounts",
      "name": "[concat(parameters('vmNodeTypeStorageAccountNames')[{Node type storage account name index for current node type}], copyIndex())]",
      "location": "[resourceGroup().location]",
      "copy": {
        "name": "nodetype{Index of current node type}storageloop",
        "count": "[parameters('vmNodeTypeSkuCapacity')[{node type sku capacity index for current node type}]]"
      },
      "tags": {
        "resourceType": "Service Fabric",
        "clusterName": "[parameters('clusterName')]",
        "displayName": "NodeType{Index of current node type}StorageAccounts"
      },
      "properties": {
        "accountType": "[parameters('vmNodeTypeStorageAccountTypes')[{storage account name index for current node type]]"
      }
    }

This will provision as many storage accounts as the number of node types in the cluster to store the VHD's of all nodes in each node type (virtual machine scale set). 

2. Add the subnets in the Virtual network resource by adding the elements in following format to the subnets array in the properties tag of the virtual network:

 {
            "name": "[variables('vmNodeType{Node type index}SubnetName')]",
            "properties": {
              "addressPrefix": "[variables('vmNodeType{Node type index}SubnetPrefix')]"
            }
 }

This will populate as many subnets as the node types to support connected devices in each subnet and will map the subnet name with the previously declared CIDR subnet prefix and IP range and add them to the virtual network.

3. Virtual machine scale set changes:

* One can add custom ETW Providers by adding the elements in following syntax to the EtwProviders in WadCfg property under the VMDiagnosticSettingsExtension Settings of the Virtual Machine Scale set resource:

{
                              "provider": "Custom-Provider",
                              "scheduledTransferPeriod": "PT5M",
                              "DefaultEvents": {
                                "eventDestination": "ETWEventTable"
                              }
}

4. In the same resource add the elements to the array vhdContainers under the osDisk property of the storageProfile setting of the virtual machine scale set resource:

[concat('https://',parameters('vmNodeTypeStorageAccountNames')[copyIndex()],'{index of node count}.blob.core.windows.net/vhds')]

_**Note: Add as many elements as the highest number of node count in a given node type to ensure that in each storage account of the node type, enough URI's are reserved to accomodate VHD's of all the nodes in the node type. This is a work around to prevent excessive storage accounts and hold all node type VM VHD's in one storage account provisioned for that node type.**_

5. Add as many elements as the number of node types to the nodeTypes array in properties of the Service fabric cluster resource in the following format:

 {
            "name": "[parameters('vmNodeTypeNames')[{Node type index}]]",
            "placementProperties": {},
            "capacities": {},
            "applicationPorts": {
              "endPort": "30000",
              "startPort": "20000"
            },
            "clientConnectionEndpointPort": "[parameters('fabricTcpGatewayPort')]",
            "durabilityLevel": "[parameters('clusterNodeTypeDurability')[{node type durability index}]]",
            "ephemeralPorts": {
              "endPort": "65534",
              "startPort": "49152"
            },
            "httpGatewayEndpointPort": "[parameters('fabricHttpGatewayPort')]",
            "isPrimary": "[parameters('clusterNodeTypePrimary')[{node type primary index}]]",
            "vmInstanceCount": "[parameters('vmNodeTypeSkuCapacity')[{node type sku capacity index}]]"
 }

This will attach each Virtual Machine Scale set as a node type to the Service fabric cluster and will map the various node type settings with the configurations defined before. Settings for each node type can be customized here.

## Deploy the sevice fabric cluster ARM template as is to get 5 node type, 20 node cluster or modify the template to customize node types and node counts and deploy the custom template after executing the key vault ARM template and the PowerShell scripts for basework.

1. Ensure that the there are no errors in ARM template deployment and the output is successful.

2. Ensure that the users are added to the AD groups which have been configured to have key vault permissions as well as access to the cluster application.

3. Open the cluster explorer URL and login with the credentials of user belonging to the AD group configured for authentication.

4. After successfully logging into the cluster explorer one can view the node health status.

### Optional : Use the 
