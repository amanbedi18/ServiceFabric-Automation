<#
.VERSION
1.0.3

.SYNOPSIS
Common script, do not call it directly.
#>

Param
(
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $userName,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $password
)

Try
{
	if($headers){
		Exit
	}
}
Catch
{
}

Try
{
    $FilePath = Join-Path $PSScriptRoot "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    Add-Type -Path $FilePath
}
Catch
{
    Write-Warning $_.Exception.Message
}

function GetRESTHeaders()
{
	# Use common client 
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    $redirectUrl = "urn:ietf:wg:oauth:2.0:oob"

	$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
   
    $creds = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential" -ArgumentList $userName,$secpasswd 
    $authenticationContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList $authString, $FALSE

    $accessToken = $authenticationContext.AcquireToken($resourceUrl,$clientId, $creds).AccessToken
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $accessToken)
    return $headers
}

function CallGraphAPI($uri, $headers, $body)
{
    $json = $body | ConvertTo-Json -Depth 4 -Compress
    return (Invoke-RestMethod $uri -Method Post -Headers $headers -Body $json -ContentType "application/json")
}

function AssertNotNull($obj, $msg){
	Try
	{    
		if($obj -eq $null -or $obj.Length -eq 0){ 
			Write-Warning $msg
			Exit
		}
	}
	Catch
	{}
}

# Regional settings
switch ($Location)
{
    "china"
    {
        $resourceUrl = "https://graph.chinacloudapi.cn"
        $authString = "https://login.partner.microsoftonline.cn/" + $TenantId
    }

    default
    {
        $resourceUrl = "https://graph.windows.net"
        $authString = "https://login.microsoftonline.com/" + $TenantId
    }
}

$headers = GetRESTHeaders

if ($ClusterName)
{
    $WebApplicationName = $ClusterName + "_Cluster"
    $WebApplicationUri = "https://$ClusterName"
    $NativeClientApplicationName = $ClusterName + "_Client"
}
