# Creates or Reconfigures an IIS Application Pool

Properties {
    # Application pool name
    # The name of the application pool that the application will run under.
    $appPoolName = $null

    # Identity Type
    # The type of identity that the application pool will be using.
    $appPoolIdentityType = 3

    # Specific User Name
    # (Specific User) The user name to use with the application pool identity.
    $appPoolIdentityUser = $null

    # Specific User Password
    # (Specific User) The password for the specific user to use with the application pool identity.
    $appPoolIdentityPassword = $null

    # Enable 32-Bit Applications
    # Allows the application pool to run 32-bit applications when running on 64-bit windows.
    $appPoolEnable32BitAppOnWin64 = $true

    # Start Automatically
    # Automatically start the application pool when the application pool is created or whenever IIS is started.
    $appPoolAutoStart = $true

    # Managed Runtime iis-apppool-deleteVersion
    # Specifies the CLR version to be used by the application pool.
    $appPoolManagedRuntimeVersion = "v4.0"

    # Managed Pipeline Mode
    # Specifies the request-processing mode that is used to process requests for managed content.
    # 0 = Integrated | 1 = Classic
    $appPoolManagedPipelineMode = 0
}

Task Default -depends CreateAppPool

Task CreateAppPool -requiredVariables appPoolName {
    Validate-Parameter $appPoolName -parameterName "Application Pool Name"
    Validate-Parameter $appPoolIdentityType -parameterName "Identity Type"
    if ($appPoolIdentityType -eq 3)
    {
        Validate-Parameter $appPoolIdentityUser -parameterName "Identity UserName"
        Validate-Parameter $appPoolIdentityPassword -parameterName "Identity Password"
    }
    Validate-Parameter $appPoolAutoStart -parameterName "AutoStart"
    Validate-Parameter $appPoolEnable32BitAppOnWin64 -parameterName "Enable 32-Bit Apps on 64-bit Windows"

    Validate-Parameter $appPoolManagedRuntimeVersion -parameterName "Managed Runtime Version"
    Validate-Parameter $appPoolManagedPipelineMode -parameterName "Managed Pipeline Mode"

    Import-Module WebAdministration -ErrorAction SilentlyContinue

    ## --------------------------------------------------------------------------------------
    ## Run
    ## --------------------------------------------------------------------------------------

    pushd IIS:\AppPools\

    $existingPool = gci | Where {$_.Name -eq $appPoolName} | Select-Object -First 1
	$pool = $null

    if ($existingPool -eq $null)
    {
        Write-Output "Creating Application Pool '$appPoolName'"
		# TODO: check if this can be made better
        New-WebAppPool -Name $appPoolName
		$pool = Get-Item $appPoolName
        #$iis.CommitChanges()
    }
    else
    {
		$pool = Get-Item $appPoolName
        Write-Output "Application Pool '$appPoolName' already exists, reconfiguring."
    }

    #$pool = $iis.ApplicationPools | Where {$_.Name -eq $appPoolName} | Select-Object -First 1

    Write-Output "Setting: AutoStart = $appPoolAutoStart"
    $pool.autoStart = $appPoolAutoStart

    Write-Output "Setting: Enable32BitAppOnWin64 = $appPoolEnable32BitAppOnWin64"
    $pool.enable32BitAppOnWin64 = $appPoolEnable32BitAppOnWin64

    Write-Output "Setting: IdentityType = $appPoolIdentityType"
    $pool.processModel.IdentityType = $appPoolIdentityType

    IF ($appPoolIdentityType -eq 3)
    {
        Write-Output "Setting: UserName = $appPoolIdentityUser"
        $pool.processModel.UserName = $appPoolIdentityUser

        Write-Output "Setting: Password = [Omitted For Security]"
        $pool.processModel.Password = $appPoolIdentityPassword
    }

    Write-Output "Setting: ManagedRuntimeVersion = $appPoolManagedRuntimeVersion"
    $pool.managedRuntimeVersion = $appPoolManagedRuntimeVersion

    Write-Output "Setting: ManagedPipelineMode = $appPoolManagedPipelineMode"
    $pool.managedPipelineMode = $appPoolManagedPipelineMode

	$pool | Set-Item
    popd

    Write-Host "Created the AppPool $appPoolName" -ForegroundColor Green
}

## --------------------------------------------------------------------------------------
## Helpers
## --------------------------------------------------------------------------------------
# Helper for validating input parameters
function Validate-Parameter([string]$foo, [string[]]$validInput, $parameterName) {
    IF (! $parameterName -contains "Password")
    {
        Write-Host "${parameterName}: $foo"
    }
    if (! $foo) {
        throw "No value was set for $parameterName, and it cannot be empty"
    }
}

