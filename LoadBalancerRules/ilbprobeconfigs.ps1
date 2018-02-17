Param(
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]	
    [string] $resourceGroup
)

Import-Module Azure -ErrorAction SilentlyContinue
Set-StrictMode -Version 3

    <# Add Probe #>

    $slb = get-AzureRmLoadBalancer -Name "{Name of load balancer}"  -ResourceGroupName $resourceGroup

    Add-AzureRmLoadBalancerProbeConfig -Name "{Name of probe}" -Protocol tcp -LoadBalancer $slb -Port "{Port No.}" -IntervalInSeconds "{Interval}" -ProbeCount "{Probe Count}" | Set-AzureRmLoadBalancer

    <# Add Load Balancing Rule #>

    $dmProbe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $slb -Name "{Name of probe}"

    $frontendIPConfig = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $slb -Name LoadBalancerIPConfig

    $backendendAddressPool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $slb -Name LoadBalancerBEAddressPool

    $slb = get-AzureRmLoadBalancer -Name "{Name of load balancer}" -ResourceGroupName $resourceGroup

    Add-AzureRmLoadBalancerRuleConfig -LoadBalancer $slb -Name "{Name of load balancing rule}" -BackendAddressPool $backendendAddressPool -BackendPort "{Backend port no}" -FrontendIpConfiguration $frontendIPConfig -FrontendPort "{Frontend port no}" -IdleTimeoutInMinutes "{Idle timeout}" -Probe $dmProbe -Protocol Tcp | Set-AzureRmLoadBalancer


