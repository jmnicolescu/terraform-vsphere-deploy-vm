# ----------------------------------------------------------------
# File Name: 10-save_credentials.ps1
#
# PowerCLI script to create and store the credentials in a file
#
# Sat Mar 28 13:00:02 GMT 2020 - juliusn - initial script
# ----------------------------------------------------------------

write-host "Saving credentials for administrator@flexlab.local" -foreground green
write-host "Enter the credentials for vCenter Server"  -foreground green

#write-host "Saving credentials for zjulius.nicolescu" -foreground green
#write-host "Enter the credentials for vCenter Server" -foreground green

$credential = Get-Credential
$credential | Export-Clixml -Path 10_credentials_vc.cred
