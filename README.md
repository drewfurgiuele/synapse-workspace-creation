# synapse-workspace-creation

This repository is set up to host automations scripts around the creation of Azure Synapse Analytics workspaces. Included in this codebase are two folders:

* powershell-scripts: A PowerShell cmdlet-based script that creates a new Synapse Workspace, empty Dedicated pool (which is paused on creation), new "small" spark pool, and a private endpoint connection to both the workspace and workspace storage account (if requested)
* arm-template: A default, bare-bones workspace deployment template which you can run through ```New-AzResourceGroupDeployment```

## Requirements
* Azure PowerShell Module
* Az.Synapse Module
* A current Azure context (```Connect-AzAccount```) in the subscription you want to deploy to (```Set-AzContext```)