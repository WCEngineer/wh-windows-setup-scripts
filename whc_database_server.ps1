# Description: Boxstarter Script
# Author: Microsoft
# Common settings for Whittet-Higgins database servers

If ($Boxstarter.StopOnPackageFailure) { $Boxstarter.StopOnPackageFailure = $false }

Disable-UAC

# Get the base URI path from the ScriptToCall value
$bstrappackage = "-bootstrapPackage"
$helperUri = $Boxstarter['ScriptToCall']
$strpos = $helperUri.IndexOf($bstrappackage)
$helperUri = $helperUri.Substring($strpos + $bstrappackage.Length)
$helperUri = $helperUri.TrimStart("'", " ")
$helperUri = $helperUri.TrimEnd("'", " ")
$helperUri = $helperUri.Substring(0, $helperUri.LastIndexOf("/"))
$helperUri += "/scripts"
Write-Host "helper script base URI is $helperUri"

function drawLine { Write-Host '------------------------------' }

function executeScript {
	Param ([string]$script)
	drawLine;
	Write-Host "executing $helperUri/$script ..."
	Invoke-Expression ((New-Object net.webclient).DownloadString("$helperUri/$script")) -ErrorAction Continue
	drawLine;
	RefreshEnv;
	Start-Sleep -Seconds 1;
}

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

#--- Powershell Module Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

#--- Package Manager ---
executeScript 'ConfigureChocolatey.ps1';
executeScript 'PackageManagement.ps1';

#--- Setting up Windows ---
Set-TimeZone -Id "Eastern Standard Time"
executeScript 'SetNTPDomainMember.ps1';
executeScript 'EnableIPv6.ps1';
executeScript "CommonDevTools.ps1";

#--- Setting up programs for typical every-day use
executeScript 'PasswordManager.ps1';

#--- Administrative Tools ---
executeScript 'FileAndStorageUtils.ps1'

executeScript 'ConfigureGit.ps1';

#--- Configure Powershell Profile for PSReadline ---
executeScript 'ConfigurePowerShell.ps1';

#--- reenabling critial items ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula
