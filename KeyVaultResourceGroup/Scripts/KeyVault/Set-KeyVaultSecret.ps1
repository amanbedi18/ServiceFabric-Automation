#Requires -Module AzureRM.KeyVault

# Use this script to create a new Key Vault secret, if secret already exists it will create a new version

param(
	[string] [Parameter(Mandatory=$true)] $KeyVaultName,
    [string] [Parameter(Mandatory=$true)] $KeyVaultSecretName,
    [securestring] [Parameter(Mandatory=$true)] $KeyVaultSecretValue    
)

$NewSecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName -SecretValue $KeyVaultSecretValue -Verbose

Write-Host
Write-Host "Source Vault Resource Id: "$(Get-AzureRmKeyVault -VaultName $KeyVaultName).ResourceId
