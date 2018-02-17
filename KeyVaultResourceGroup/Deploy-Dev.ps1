#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $ASFClusterName = '',
	[string] [Parameter(Mandatory=$true)] $ASFServiceName = '',
	[string] [Parameter(Mandatory=$true)] $ASFLocation = '',
	[string] [Parameter(Mandatory=$true)] $KeyVaultName = '',
	[string] [Parameter(Mandatory=$true)] $KeyVaultASFClusterCertificateSecretName = '',
	[string] [Parameter(Mandatory=$true)] $KeyVaultASFClusterCertificatePassword = '',
    [String] [Parameter(Mandatory=$true)] $userName,
	[String] [Parameter(Mandatory=$true)] $password,
	[String] [Parameter(Mandatory=$true)] $subscriptionName
)

Import-Module Azure -ErrorAction SilentlyContinue

Set-StrictMode -Version 3
$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)

$ClusterDNSName = "$ASFClusterName.$ASFLocation.cloudapp.azure.com"
$ServiceDNSName = "$ASFServiceName.$ASFLocation.cloudapp.azure.com"
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

# Azure Service Fabric explorer url
$ClusterResourceExplorerUrl= "https://$ClusterDNSName`:19080/Explorer/index.html"

Login-AzureRmAccount -Credential $mycreds -SubscriptionName $subscriptionName

$TenantId = (Get-AzureRmContext).Tenant.TenantId

# Set up Azure Active Directory for client authentication
. $ScriptDir\Scripts\MicrosoftAzureServiceFabric-AADHelpers\SetupApplications.ps1 -userName $userName -password $password -subscriptionName $subscriptionName -TenantId $TenantId -ClusterName $ASFClusterName -WebApplicationReplyUrl $ClusterResourceExplorerUrl 

# Add clsuter authentication certificate to Key Vault
### Self Signed certificate
<#. $ScriptDir\Scripts\KeyVault\New-ServiceFabricClusterCertificate.ps1 -CertDNSName $ClusterDNSName -KeyVaultName $KeyVaultName -KeyVaultSecretName $KeyVaultASFClusterCertificateSecretName -Password $KeyVaultASFClusterCertificatePassword #>
. $ScriptDir\Scripts\KeyVault\Set-ServiceFabricClusterCertificate.ps1 -Password $KeyVaultASFClusterCertificatePassword -ClusterDNSName $ClusterDNSName -KeyVaultName $KeyVaultName -KeyVaultSecretName $KeyVaultASFClusterCertificateSecretName

## Set up secret in key vault for node vm's password
#. $ScriptDir\Scripts\KeyVault\Set-KeyVaultSecret.ps1 -KeyVaultName $KeyVaultName -KeyVaultSecretName $NodeAdminPasswordSecretName -KeyVaultSecretValue ''