# This is an amalgamation of several different runbooks on GitHub


Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $resourcegroup,    
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $mi_principal_id, 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $vmlist, 
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
    [String] 
    $action
)

Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect to Azure with user-assigned managed identity
# Don't do what Microsoft say - they use Client_Id here but it needs to be
# the managed_identity_principal_id
$AzureContext = (Connect-AzAccount -Identity -AccountId $mi_principal_id).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Account ID of current context: " $AzureContext.Account.Id

# Separate our vmlist into an arraay we can iterate over
$AzureVMs = $vmlist.Split(",") 
[System.Collections.ArrayList]$VMsToChange = $AzureVMs 

# Loop through one or more VMs which will be passed in from the terraform as a list
# If the list is empty it will skip the block
foreach ($VM in $VMsToChange) {

    $status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $VM -Status -DefaultProfile $AzureContext).Statuses[1].Code
    Write-Output "`r`n Initial $VM VM status: $status `r`n `r`n"

    switch ($action) {
        "Start" {
            # Start the VM
            try {
                Write-Output "Starting VM $VM ..."
                Start-AzVM -Name $VM -ResourceGroupName $resourcegroup -DefaultProfile $AzureContext
            }
            catch {
                $ErrorMessage = $_.Exception.message
                Write-Error ("Error starting the VM $VM : " + $ErrorMessage)
                Break
            }
        }
        "Stop" {
            # Stop the VM
            try {
                Write-Output "Stopping VM $VM ..."
                Stop-AzVM -Name $VM -ResourceGroupName $resourcegroup -DefaultProfile $AzureContext -Force
            }
            catch {
                $ErrorMessage = $_.Exception.message
                Write-Error ("Error stopping the VM $VM : " + $ErrorMessage)
                Break
            }
        }    
    }

    $status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $VM -Status -DefaultProfile $AzureContext).Statuses[1].Code
    Write-Output "`r`n Final $VM VM status: $status `r`n `r`n"

}

Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
