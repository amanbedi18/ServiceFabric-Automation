param(
    [string] [Parameter(Mandatory=$true)] $Password,
    [string] [Parameter(Mandatory=$true)] $CertName
)

$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$CertFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "\$CertName.pfx")

$now = [System.DateTime]::Now
$5yearfromnow = $now.AddYears(5)

$NewCert = New-SelfSignedCertificate -Type Custom -Subject "CN=DPClientCert" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") -KeyUsage DigitalSignature -KeyAlgorithm RSA -KeyLength 2048 -CertStoreLocation Cert:\LocalMachine\My -NotAfter $5yearfromnow

Export-PfxCertificate -FilePath $CertFileFullPath -Password $SecurePassword -Cert $NewCert
Write-Host "Certificate Thumbprint : "$NewCert.Thumbprint