Workflow Stop-Start-AzureVM
# Adapted to use Managed Identity and modern powershell from Microsoft gallery version
{ 
    Param 
    (    
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $client_id, 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $azurevmlist, 
        [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
        [String] 
        $action 
    ) 
     
    #$credential = Get-AutomationPSCredential -Name 'AzureCredential' 
    #Login-AzureRmAccount -Credential $credential 
    #Select-AzureRmSubscription -SubscriptionId $AzureSubscriptionId 
 
	# Ensures you do not inherit an AzContext in your runbook
	Disable-AzContextAutosave -Scope Process

	# Connect to Azure with system-assigned managed identity - from deployment
	$AzureContext = (Connect-AzAccount -Identity -AccountId $client_id).context

    # To use this runbook with a system assigned managed identity, replace the above with
    # $AzureContext = (Connect-AzAccount -Identity).context

	# set and store context
	$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

	# Get all VM names from the subscription
	Get-AzVM -DefaultProfile $AzureContext | Select Name



    if($azurevmlist -ne "All") 
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
        if(!(Get-AzureRmVM | ? {$_.Name -eq $AzureVM})) 
        { 
            throw " AzureVM : [$AzureVM] - Does not exist! - Check your inputs " 
        } 
    } 
 
    if($action -eq "Stop") 
    { 
        Write-Output "Stopping VMs"; 
        foreach -parallel ($AzureVM in $AzureVMsToHandle) 
        { 
            Get-AzureRmVM | ? {$_.Name -eq $AzureVM} | Stop-AzureRmVM -Force 
        } 
    } 
    else 
    { 
        Write-Output "Starting VMs"; 
        foreach -parallel ($AzureVM in $AzureVMsToHandle) 
        { 
            Get-AzureRmVM | ? {$_.Name -eq $AzureVM} | Start-AzureRmVM 
        } 
    } 
}