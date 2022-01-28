Param(
 [string]$automationaccount,
 [string]$resourcegroup,
 [string]$vmname,
 [string]$method,
 [string]$mi_client_id,
 [string]$mi_principal_id
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

#Get-AzUserAssignedIdentity -ResourceGroupName $resourcegroup -Name $mi_principal_id).PrincipalId
#$UAMI = (Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup -Name $userAssignedManagedIdentity).PrincipalId


# Connect using a Managed Service Identity
# try {
#         $AzureContext = (Connect-AzAccount -Identity).context
#     }
# catch{
#         Write-Output "There is no system-assigned user identity. Aborting.";
#        exit
#    }


# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $mi_principal_id).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Account ID of current context: " $AzureContext.Account.Id
<#
if ($method -eq "sa")
    {
        Write-Output "Using system-assigned managed identity"
    }
elseif ($method -eq "ua")
    {
        Write-Output "Using user-assigned managed identity"

        # Connects using the Managed Service Identity of the named user-assigned managed identity
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourcegroup `
            -Name $mi_principal_id
        
            -DefaultProfile $AzureContext

        # validates assignment only, not perms
        if ((Get-AzAutomationAccount -ResourceGroupName $resourcegroup `
                -Name $automationaccount `
                -DefaultProfile $AzureContext).Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId))
            {
                $AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

                # set and store context
           }
        else {
                Write-Output "Invalid or unassigned user-assigned managed identity"
                exit
            }
    }
else {
        Write-Output "Invalid method. Choose us or sa."
        exit
     }
#>
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

