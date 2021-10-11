#Requires -Modules Az.Synapse
[cmdletbinding()]
Param(
    [Parameter(Mandatory=$True)] [String] $ResourceGroupName,
    [Parameter(Mandatory=$True)] [String] $Location,
    [Parameter(Mandatory=$True)] [String] $WorkspaceName,
    [Parameter(Mandatory=$True)] [String] $WorkspaceManagedResourceGroupName,    
    [Parameter(Mandatory=$True)] [String] $DefaultStorageAccountName,
    [Parameter(Mandatory=$True)] [String] $DefaultStorageFileSystemName,    
    [Parameter(Mandatory=$True)] [String] $PrivateEndpointVNetName,
    [Parameter(Mandatory=$True)] [String] $PrivateEndpointSubnetName,    
    [Parameter(Mandatory=$True)] [String] $SQLPoolName,
    [Parameter(Mandatory=$True)] [pscredential] $SQLCredential,
    [Parameter(Mandatory=$False)] [String] $SqlPoolServiceTier = "DW100c",
    [Parameter(Mandatory=$True)] [String] $SparkPoolName,
    [Parameter(Mandatory=$False)] [int] $SparkPoolMinNodes = 3,
    [Parameter(Mandatory=$False)] [int] $SparkPoolMaxNodes = 3,
    [Parameter(Mandatory=$False)] [String] $SparkPoolNodeSize = "Small",
    [Parameter(Mandatory=$False)] [String] $SparkVersion = "3.1",
    [Parameter(Mandatory=$False)] [Hashtable] $Tags,
    [Parameter(Mandatory=$False)] [Switch] $CreateWorkspacePrivateEndpoints,
    [Parameter(Mandatory=$False)] [Switch] $CreateStorageAccountPrivateEndpoint

)
begin {
    try {
        $AzContext = Get-AzContext
    } catch {
        throw "Unable to fetch current Azure Context (Are you logged in via PowerShell?)"
    }

    try {
        $RG = Get-AzResourceGroup -Name $ResourceGroupName
    } catch {
        throw "Unable to find resource group (are you in the right subscritpion?)"
    }

    if ($WorkspaceName -cnotmatch "^[^A-Z]*$" -or $WorkspaceName.Length -gt 16)
    {
        throw "Workspace name must be all lower case and less than 15 characters"
    }
    if ($DefaultStorageAccountName -cnotmatch "^[^A-Z]*$" -or $DefaultStorageAccountName.Length -gt 25)
    {
        throw "The workspace default storage account name must be all lower case and less than 25 characters"
    }
    if ($SQLPoolName -cnotmatch "^[^A-Z]*$" -or $SQLPoolName.Length -gt 16)
    {
        throw "The dedicated SQL pool name must be all lower case and less than 15 characters"
    }
    if ($SparkPoolName -cnotmatch "^[^A-Z]*$" -or $SparkPoolName.Length -gt 16)
    {
        throw "The Spark pool name Workspace name must be all lower case and less than 15 characters"
    }

    #Verify Storage account and container exist
    $StorageAccount = Get-AzStorageAccount -Name $DefaultStorageAccountName -ResourceGroupName $ResourceGroupName

    #Verify network ans subnet
    try {
        $vnet = Get-AzVirtualNetwork -Name $PrivateEndpointVNetName -ResourceGroupName $ResourceGroupName
        $subnet = $vnet.Subnets | where-object {$_.name -eq $PrivateEndpointSubnetName}
    } catch {
        throw "Unable to validate target private endpoint virtual network/subnet configuration. Did you supply the correct VNet and subnet name?"
    }
}

process {
    Write-Verbose "Deploying workspace..."
    # Create workspace
    $ManagedVNetConfiguration = New-AzSynapseManagedVirtualNetworkConfig -PreventDataExfiltration
    $Workspace = New-AzSynapseWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location -SqlAdministratorLoginCredential $SQLCredential -DefaultDataLakeStorageAccountName $DefaultStorageAccountName -DefaultDataLakeStorageFilesystem $DefaultStorageFileSystemName -ManagedVirtualNetwork $ManagedVNetConfiguration -ManagedResourceGroupName $WorkspaceManagedResourceGroupName

    Write-Verbose "Deploying empty SQL dedicated pool..." 
    $DedicatedPool = New-AzSynapseSqlPool -ResourceGroupName $ResourceGroupName -Name $SQLPoolName -WorkspaceName $WorkspaceName -PerformanceLevel $SqlPoolServiceTier

    Write-Verbose "Stopping recently-deployed SQL dedicated pool..."
    Suspend-AzSynapseSqlPool -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -Name $SQLPoolName

    Write-Verbose "Deploying Spark pool..." 
    $SparkPool = New-AzSynapseSparkPool -ResourceGroupName $ResourceGroupName -Name $SparkPoolName -WorkspaceName $WorkspaceName -SparkVersion $SparkVersion -AutoScaleMinNodeCount $SparkPoolMinNodes -AutoScaleMaxNodeCount $SparkPoolMaxNodes -EnableAutoPause -AutoPauseDelayInMinute 60 -NodeSize $SparkPoolNodeSize


    if ($CreateWorkspacePrivateEndpoints) {
        Write-Verbose "Creating private endpoint for Workspace..."
        $dev_ws_privateEndpointConn = New-AzPrivateLinkServiceConnection -Name ($WorkspaceName + "_plsws") -PrivateLinkServiceId $Workspace.Id -GroupId “dev”
        $dev_ws_privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name ($WorkspaceName + "_pews") -Location $Location -Subnet $subnet -PrivateLinkServiceConnection $dev_ws_privateEndpointConn

        $dev_sqlondemand_privateEndpointConn = New-AzPrivateLinkServiceConnection -Name ($WorkspaceName + "_plsondemand") -PrivateLinkServiceId $Workspace.Id -GroupId “sqlondemand”
        $dev_sqlondemand_privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name ($WorkspaceName + "_peondemand") -Location $Location -Subnet $subnet -PrivateLinkServiceConnection $dev_sqlondemand_privateEndpointConn

        $dev_sql_privateEndpointConn = New-AzPrivateLinkServiceConnection -Name ($WorkspaceName + "_plssql") -PrivateLinkServiceId $Workspace.Id -GroupId “sql”
        $dev_sql_privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name ($WorkspaceName + "_pesql") -Location $Location -Subnet $subnet -PrivateLinkServiceConnection $dev_sql_privateEndpointConn

    }

    if ($CreateStorageAccountPrivateEndpoint) {
        Write-Verbose "Creating private endpoint for storage account..."    
        $storage_privateEndpointConn = New-AzPrivateLinkServiceConnection -Name ($WorkspaceName + "_storage_pls") -PrivateLinkServiceId $StorageAccount.Id -GroupId “dfs”
        $storage_privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name ($WorkspaceName + "storage_pe") -Location $Location -Subnet $subnet -PrivateLinkServiceConnection $storage_privateEndpointConn
    }
}