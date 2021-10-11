# synapse-workspace-creation

This repository is set up to host automations scripts around the creation of Azure Synapse Analytics workspaces. Included in this codebase are two folders:

* powershell-scripts: A PowerShell cmdlet-based script that creates a new Synapse Workspace, empty Dedicated pool (which is paused on creation), new "small" spark pool, and a private endpoint connection to both the workspace and workspace storage account (if requested)
* arm-template: A default, bare-bones workspace deployment template which you can run through ```New-AzResourceGroupDeployment```

## Requirements
* Azure PowerShell Module
* Az.Synapse Module
* A current Azure context (```Connect-AzAccount```) in the subscription you want to deploy to (```Set-AzContext```)

### Sample Code Disclaimer
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.