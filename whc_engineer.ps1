# Description: Boxstarter Script
# Author: Microsoft
# Common settings for Whittet-Higgins engineering workstations

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
executeScript 'SetTimeZone.ps1';
executeScript 'SetNTPDomainMember.ps1';
executeScript 'EnableIPv6.ps1';
executeScript "RemoveDefaultApps.ps1";
executeScript "CommonDevTools.ps1";

#--- Setting up programs for typical every-day use
executeScript 'Browsers.ps1';
executeScript 'OfficeTools.ps1';
executeScript 'PasswordManager.ps1';

#--- Administrative Tools ---
executeScript 'RemoteServerAdministrationTools.ps1';
executeScript 'FileAndStorageUtils.ps1'

executeScript 'ConfigureGit.ps1';

#--- Configure Powershell Profile for PSReadline ---
executeScript 'ConfigurePowerShell.ps1';

#--- William Collins Engineer Tools ---
executeScript '3DPrinting.ps1';
executeScript 'WCEngineer.ps1';

#--- Tools ---
#--- Installing VS and VS Code with Git
# See this for install args: https://chocolatey.org/packages/VisualStudio2017Community
# https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community
# https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio#list-of-workload-ids-and-component-ids
# visualstudio2017community
# visualstudio2017professional
# visualstudio2017enterprise

choco install -y visualstudio2022community --package-parameters="'--add Microsoft.VisualStudio.Component.Git'"
Update-SessionEnvironment #refreshing env due to Git install

#--- reenabling critial items ---
Enable-UAC
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula
