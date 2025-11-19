function Safe-RefreshEnv {
	try {
		$output = RefreshEnv 2>&1 | Out-String
	} catch {
		$output = $_ | Out-String
	}

	if ($output -and $output -match 'Import-Module') {
		try { Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue } catch {}
		# After importing the Chocolatey profile, try refreshenv again and display its output
		try {
			$retryOutput = RefreshEnv 2>&1 | Out-String
		} catch {
			$retryOutput = $_ | Out-String
		}
		if ($retryOutput) { Write-Host $retryOutput.Trim() }
	} else {
		if ($output) { Write-Host $output.Trim() }
	}

	return $null
}

if (([Security.Principal.WindowsPrincipal] `
			[Security.Principal.WindowsIdentity]::GetCurrent() `
	).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	#--- PowerShell ---
	choco upgrade -y powershell
	choco upgrade -y powershell-core
	choco upgrade -y winget
	Safe-RefreshEnv
}

#--- Enable Powershell Script Execution
try { Set-ExecutionPolicy Bypass -Scope CurrentUser -Force } catch {} # Do nothing if blocked by Group Policy

Safe-RefreshEnv

[ScriptBlock]$ScriptBlock = {
	function Safe-RefreshEnv {
		try {
			$output = RefreshEnv 2>&1 | Out-String
		} catch {
			$output = $_ | Out-String
		}

		if ($output -and $output -match 'Import-Module') {
			try { Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue } catch {}
			# After importing the Chocolatey profile, try refreshenv again and display its output
			try {
				$retryOutput = RefreshEnv 2>&1 | Out-String
			} catch {
				$retryOutput = $_ | Out-String
			}
			if ($retryOutput) { Write-Host $retryOutput.Trim() }
		} else {
			if ($output) { Write-Host $output.Trim() }
		}

		return $null
	}

	#--- Enable Powershell Script Execution
	try {
		Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
	} catch {
		try {
			Set-ExecutionPolicy Bypass -Scope Process -Force
		} catch {
			# Do nothing if blocked by Group Policy
		}
	}

	Safe-RefreshEnv

	if ((Get-CimInstance Win32_OperatingSystem).BuildNumber -lt 17763) {
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
	} else {
		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::SystemDefault
	}

	if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and (Get-Command -Name Install-PackageProvider -ErrorAction SilentlyContinue)) {
		Write-Host 'Installing NuGet Package Provider...'
		try {
			Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue
		} catch {}
	}

	#--- Powershell Module Repository
	if (Get-Command -Name Set-PSRepository -ErrorAction SilentlyContinue) {
		try {
			Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
		} catch {}
	}

	if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		#--- Update all modules ---
		Write-Host 'Updating all modules...'
		Update-Module -ErrorAction SilentlyContinue
	}

	Safe-RefreshEnv
	Start-Sleep -Seconds 1;

	#--- Ensure PowerShell Profile Exists
	if (-not(Test-Path $PROFILE)) {
		Write-Verbose "`$PROFILE does not exist at $PROFILE`nCreating new `$PROFILE..."
		New-Item -Path $PROFILE -ItemType File -Force
	}

	#--- Prepend a Custom Printed Message to the PowerShell Profile
	Write-Host 'Prepending Custom Message to PowerShell Profile...'
	$ProfileString = 'Write-Output "Loading Custom PowerShell Profile..."'
	if (-not(Select-String -Pattern $ProfileString -Path $PROFILE )) {
		Write-Output 'Attempting to add the following line to $PROFILE :' | Write-Debug
		Write-Output $ProfileString | Write-Debug
		Set-Content -Path $PROFILE -Value ($ProfileString, (Get-Content $PROFILE))
	}

	#--- Install & Configure the PSReadline Module
	try {
		Write-Host 'Installing PSReadLine -- [Bash-like CLI features and Optional Dependency for Powerline]'
		if (-not(Get-Module -ListAvailable -Name PSReadLine)) {
			Install-Module -Name PSReadLine -Scope CurrentUser -AllowClobber -SkipPublisherCheck -Force -Verbose
		} else { Write-Host "Module 'PSReadLine' already installed" }
		Safe-RefreshEnv
		Write-Host 'Appending Configuration for PSReadLine to PowerShell Profile...'
		$PSReadlineProfile = @(
			'# Customize PSReadline to make PowerShell behave more like Bash',
			'if (!(Get-Module PSReadLine -ErrorAction SilentlyContinue)) { Import-Module PSReadLine }',
			'Set-PSReadLineOption -EditMode Emacs -HistoryNoDuplicates -HistorySearchCursorMovesToEnd',
			# 'Set-PSReadLineOption -BellStyle Audible -DingTone 512',
			'# Creates an alias for ls like I use in Bash',
			'Set-Alias -Name v -Value Get-ChildItem'
		)
		if (-not(Select-String -Pattern $PSReadlineProfile[0] -Path $PROFILE)) {
			Write-Output 'Attempting to add the following lines to $PROFILE :' | Write-Debug
			Write-Output $PSReadlineProfile | Write-Debug
			Add-Content -Path $PROFILE -Value $PSReadlineProfile
		}
	} catch {
		Write-Host 'PSReadline failed to install' | Write-Warning
		Write-Host ' See the log for details (' $Boxstarter.Log ').' | Write-Debug
		# Move on if PSReadline install fails due to errors
	}

	#--- Install the PSWindowsUpdate Module
	try {
		Write-Host 'Installing PSWindowsUpdate'
		if (-not(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
			Install-Module -Name PSWindowsUpdate -AllowClobber -SkipPublisherCheck -Force -Verbose
		} else { Write-Host "Module 'PSWindowsUpdate' already installed" }
		Safe-RefreshEnv
	} catch {
		Write-Host 'PSWindowsUpdate failed to install' | Write-Warning
		Write-Host ' See the log for details (' $Boxstarter.Log ').' | Write-Debug
		# Move on if PSWindowsUpdate install fails due to errors
	}

	#--- Import Chocolatey Modules
	if (([Security.Principal.WindowsPrincipal] `
				[Security.Principal.WindowsIdentity]::GetCurrent() `
		).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		Write-Host 'Appending Configuration for Chocolatey to PowerShell Profile...'
		$ChocolateyProfile = @(
			'# Chocolatey profile',
			'$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"',
			'if (Test-Path($ChocolateyProfile)) { Import-Module "$ChocolateyProfile" }'
		)
		if (-not(Select-String -Pattern $ChocolateyProfile[0] -Path $PROFILE)) {
			Write-Output 'Attempting to add the following lines to $PROFILE :' | Write-Debug
			Write-Output $ChocolateyProfile | Write-Debug
			Add-Content -Path $PROFILE -Value $ChocolateyProfile
		}
	}

	Get-Content -Path $PROFILE | Set-Content -Path (Join-Path (Split-Path -Path $PROFILE -Parent) "Microsoft.VSCode_profile.ps1")

	if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		#--- Update all modules ---
		Write-Host 'Updating all modules...'
		Update-Module -ErrorAction SilentlyContinue
	}

	#--- Reset default security protocol ---
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::SystemDefault
} # End of $ScriptBlock

# Run the script block in PowerShell
Write-Host 'Configuring Windows PowerShell...' -ForegroundColor 'Green'
powershell -Command $ScriptBlock

# Run the script block in PowerShell Core
Write-Host 'Configuring PowerShell Core...' -ForegroundColor 'Green'
pwsh -Command $ScriptBlock
