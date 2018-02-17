#Requires -Module AzureRM.KeyVault

# Use this script to upload a certificate that you can use to secure a Service Fabric Cluster
# This script requires an existing KeyVault that is EnabledForDeployment.  The vault must be in the same region as the cluster.
# To create a new vault and set the EnabledForDeployment property run:
#
# New-AzureRmResourceGroup -Name KeyVaults -Location WestUS
# New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName KeyVaults -Location WestUS -EnabledForDeployment
#
# Once the certificate is uploaded and stored in the vault, the script will provide the parameter values needed for template deployment
# 

param(
    [string] [Parameter(Mandatory=$true)] $Password,
    [string] [Parameter(Mandatory=$true)] $ServiceDNSName,
    [string] [Parameter(Mandatory=$true)] $KeyVaultName,
    [string] [Parameter(Mandatory=$true)] $KeyVaultSecretName
)

$CertFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "\$ServiceDNSName.pfx")
$Bytes = [System.IO.File]::ReadAllBytes($CertFileFullPath)
$Base64 = [System.Convert]::ToBase64String($Bytes)

$JSONBlob = @{
    data = $Base64
    dataType = 'pfx'
    password = $Password
} | ConvertTo-Json

$ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($JSONBlob)
$Content = [System.Convert]::ToBase64String($ContentBytes)

$SecretValue = ConvertTo-SecureString -String $Content -AsPlainText -Force
$NewSecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName -SecretValue $SecretValue -Verbose

$CUrl = $NewSecret.Id
Write-Host ("##vso[task.setvariable variable=ApisCertURL;]$CUrl")
Write-Host $env:ApisCertURL
Write-Host "Certificate URL : "$NewSecret.Id 