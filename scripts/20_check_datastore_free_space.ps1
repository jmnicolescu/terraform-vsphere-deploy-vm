# ----------------------------------------------------------------
# File Name: 20_check_datastore_free_space.ps1
#
# PowerCLI script to check a datstore free space percentage
#
# Sat Mar 28 13:00:02 GMT 2020 - juliusn - initial script
# ----------------------------------------------------------------

param (
  [parameter(Mandatory=$true, ValueFromPipeLine=$true, ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string] $DatastoreName,
  [parameter(Mandatory=$true, ValueFromPipeLine=$true, ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$DatastoreFreeSpaceLimit  
)

if (!$DatastoreName) {
	Write-Host "[$(Get-Date)] Argument required < Datastore Name >" -ForegroundColor "red"
	exit -1
}

# -- Import PowerCLI Modules --
# get-module -ListAvailable VMware.VimAutomation.* | Import-Module | Out-Null
Import-Module VMware.VimAutomation.Cis.Core | Out-Null
Import-Module VMware.VimAutomation.Common | Out-Null
Import-Module VMware.VimAutomation.Core | Out-Null
Import-Module VMware.VimAutomation.License | Out-Null
Import-Module VMware.VimAutomation.Sdk | Out-Null
Import-Module VMware.VimAutomation.Storage | Out-Null
Import-Module VMware.VimAutomation.vds | Out-Null

Function Percentcal {
	param(
		[parameter(Mandatory = $true)]
    	[int]$InputNum1,
    	[parameter(Mandatory = $true)]
    	[int]$InputNum2)
	$InputNum1 / $InputNum2*100
}

# ----------------------------------------------------------------
# Local variables definition
# ----------------------------------------------------------------
$vCenterName		= ${env:TF_VAR_provider_vsphere_host}
$vCenterUser		= ${env:TF_VAR_provider_vsphere_user}
$vCenterPassword	= ${env:TF_VAR_provider_vsphere_password}

# ------------------------------------------------------------------------
# Connect to vCenter Server
# ------------------------------------------------------------------------
# $credential = Import-Clixml -Path 10_credentials_vc.cred
# if(!(Connect-VIServer -Server $vCenterName -Credential $credential)) {

Write-host "`n[$(Get-Date)] Connecting to vCenter Server $vCenterName" -ForegroundColor "green"
if (!(Connect-VIServer -Server $vCenterName -protocol https -User $vCenterUser -Password $vCenterPassword)) {
	Write-Host "[$(Get-Date)] Unable to connect to vCenter!" -ForegroundColor "red"
	exit -1
}

$ds = Get-Datastore $DatastoreName
$DsPercentFree = Percentcal $ds.FreeSpaceMB $ds.CapacityMB
$DsPercentFree = "{0:N2}"-f $DsPercentFree

# Output to provide the Datastore name, UsedSpace in GB , TotalSpace in GB and % of free space on the datastore.
$ds | Add-Member -type NoteProperty -name PercentFree -value $DsPercentFree
$ds | Select Name,@{N="UsedSpaceGB";E={[Math]::Round(($_.ExtensionData.Summary.Capacity -$_.ExtensionData.Summary.FreeSpace)/1GB,0)}},@{N="TotalSpaceGB";E={[Math]::Round(($_.ExtensionData.Summary.Capacity)/1GB,0)}} ,PercentFree

if ($DsPercentFree -gt $DatastoreFreeSpaceLimit) {
	Write-Host "[$(Get-Date)] All good! Datastore $DatastoreName FreeSpace% is $($DsPercentFree)% which is grater than the limit $($DatastoreFreeSpaceLimit)%" -ForegroundColor "green"
}
	else {
		Write-Host "---------------------------------------------------------------------------------------------------------" -ForegroundColor "red"
		Write-Host "[$(Get-Date)] Datastore $DatastoreName Free Space is $($DsPercentFree)% which is less than the limit $($DatastoreFreeSpaceLimit)%" -ForegroundColor "red"
		Write-Host "---------------------------------------------------------------------------------------------------------" -ForegroundColor "red"
		exit -1
}

# ------------------------------------------------------------------------
# Disconnect from vCenter Server
# ------------------------------------------------------------------------
Write-host  "[$($(Get-Date))] Disconnecting from vCenter Servers $vCenterName"
Disconnect-Viserver -Server $vCenterName -Force -confirm:$false | Out-Null
exit 0