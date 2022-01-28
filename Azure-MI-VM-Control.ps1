Param(
 [string]$vmname,
 [string]$mi_principal_id
 [string]$resourcegroup
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect to Azure with user-assigned managed identity
# Don't do what Microsoft say - they use client_id here but it needs to be
# the managed_identity_principal_id
$AzureContext = (Connect-AzAccount -Identity -AccountId $mi_principal_id).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Account ID of current context: " $AzureContext.Account.Id

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $vmname -Status -DefaultProfile $AzureContext).Statuses[1].Code

Write-Output "`r`n Beginning VM status: $status `r`n"

# Start or stop VM based on current state
if($status -eq "Powerstate/deallocated")
    {
        Start-AzVM -Name $vmname -ResourceGroupName $resourcegroup -DefaultProfile $AzureContext
    }
elseif ($status -eq "Powerstate/running")
    {
        Stop-AzVM -Name $vmname -ResourceGroupName $resourcegroup -DefaultProfile $AzureContext -Force
    }

# Get new state of VM
$status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $vmname -Status -DefaultProfile $AzureContext).Statuses[1].Code  

Write-Output "`r`n Ending VM status: $status `r`n `r`n"
