# Adapted to use Managed Identity and modern powershell from Microsoft gallery version

Param 
(    
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

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect to Azure with user-assigned managed identity
# Don't do what Microsoft say - they use client_id here but it needs to be
# the managed_identity_principal_id
$AzureContext = (Connect-AzAccount -Identity -AccountId $mi_principal_id).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Account ID of current context: " $AzureContext.Account.Id

# Get all VM names from the subscription
Get-AzVM -DefaultProfile $AzureContext | Select-Object Name



if($vmlist -ne "All") 
{ 
    $AzureVMs = $azurevmlist.Split(",") 
    [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
} 
else 
{ 
    $AzureVMs = (Get-AzureRmVM).Name 
    [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 

} 

foreach($AzureVM in $AzureVMsToHandle) 
{ 
    if(!(Get-AzureRmVM | Where-Object {$_.Name -eq $AzureVM})) 
    { 
        throw " AzureVM : [$AzureVM] - Does not exist! - Check your inputs " 
    } else {
        # Get current state of VM
        $status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $AzureVM -Status -DefaultProfile $AzureContext).Statuses[1].Code
        Write-Output "`r`n Beginning VM status: $status `r`n"   
    }
} 

if($action -eq "Stop") 
{ 
    Write-Output "Stopping VMs";
    $workflow = $_
    $AzureVMsToHandle |foreach-object -parallel 
    { 
        Get-AzureRmVM | Where-Object {$workflow.Name -eq $_} | Stop-AzureRmVM -Force 
    } 
} 
else 
{ 
    Write-Output "Starting VMs";
    $workflow = $_ 
    $AzureVMsToHandle |foreach-object -parallel
    { 
        Get-AzureRmVM | Where-Object {$workflow.Name -eq $_} | Start-AzureRmVM 
    } 
} 
