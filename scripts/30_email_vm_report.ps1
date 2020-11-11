# ----------------------------------------------------------------
# File Name: 30_email_vm_report.ps1
#
# PowerCLI script to email VM deployed report
#
# Sat Mar 28 13:00:02 GMT 2020 - juliusn - initial script
# ----------------------------------------------------------------

param (
  [parameter(Mandatory=$true, ValueFromPipeLine=$true, ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string] $vCenterUsed,
  [parameter(Mandatory=$true, ValueFromPipeLine=$true, ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$VmDeployed  
)

if (!$vCenterUsed) {
	Write-Host "[$(Get-Date)] Argument required < vCenter Name >" -ForegroundColor "red"
	exit -1
}
if (!$VmDeployed) {
	Write-Host "[$(Get-Date)] Argument required < VM Name >" -ForegroundColor "red"
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
	Exit
}

$date = (get-date -Format d/M/yyyy)
$Report = "VM deployed date - $date"

$MailParam = @{ 
    To         = "juliusn@flexlab.local" 
    From       = "juliusn@flexlab.local"
    SmtpServer = "192.168.111.111"
    Subject    = "New VM deployed " + $VmDeployed
    body       = ([string]$Report)
}

Write-host "`n[$(Get-Date)] Sending email report - $Report" -ForegroundColor "green"
#Send-MailMessage @MailParam -BodyAsHtml

# ------------------------------------------------------------------------
# Disconnect from vCenter Server
# ------------------------------------------------------------------------
Write-host  "[$($(Get-Date))] Disconnecting from vCenter Servers $vCenterName"
Disconnect-Viserver -Server $vCenterName -Force -confirm:$false | Out-Null
