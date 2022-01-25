# Adapted to use Managed Identity and modern powershell from Microsoft gallery version

Param 
(    
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $Client_Id, 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $AzureVMList, 
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
    [String] 
    $Action 
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity - from deployment
$AzureContext = (Connect-AzAccount -Identity -AccountId $Client_Id).context

# To use this runbook with a system assigned managed identity, replace the above with
# $AzureContext = (Connect-AzAccount -Identity).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

# Get all VM names from the subscription
Get-AzVM -DefaultProfile $AzureContext | Select-Object Name



if($AzureVMList -ne "All") 
{ 
    $AzureVMs = $AzureVMList.Split(",") 
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
    } 
} 

if($Action -eq "Stop") 
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