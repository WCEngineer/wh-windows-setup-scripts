# Description: Boxstarter Script
# Author: Microsoft
# Common settings for Whittet-Higgins office workstations

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

#--- Setting up Windows ---
executeScript "FileExplorerSettings.ps1";
executeScript "RemoveDefaultApps.ps1";

#--- Package Manager ---
executeScript 'InstallWinGet.ps1';
executeScript 'PackageManagement.ps1';

executeScript 'ConfigureGit.ps1';

#--- Configure Powershell Profile for PSReadline ---
executeScript 'ConfigurePowerShell.ps1';

#--- Setting up Chocolatey ---
executeScript 'ChocolateyExtensions.ps1';
executeScript 'ChocolateyGUI.ps1';

#--- Graphics Driver Support
#executeScript 'NvidiaGraphics.ps1';

#--- Setting up programs for typical every-day use
executeScript 'Browsers.ps1';
executeScript 'OfficeTools.ps1';
executeScript 'PasswordManager.ps1';
executeScript 'FileAndStorageUtils'

#--- Windows Privacy Settings ---
executeScript 'PrivacySettings.ps1';

#--- Whittet-Higgins Custom Setup ---
executeScript 'DisableIPv6.ps1';

#--- reenabling critial items ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula
