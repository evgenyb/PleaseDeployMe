Properties {
    $chocolateyBin = [Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine") + "\bin\chocolatey.exe"

    # The ID of an application package in the https://chocolatey.org repository. Required. Example: Git.
    $chocolateyPackageId = $null

    # If a specific version of the Chocolatey package is required enter it here.
    # Otherwise, leave this field blank to use the latest version. Example: 2.3.4.
    $chocolateyPackageVersion = $null

    $packageConfigPath = "$buildDir\choco-packages.config"
}

#Task default -depends InstallChocolateyPackage
Task default

Task InstallChocolateyPackages `
    -description 'Installs all packages in the config file.' `
    -depends EnsureChocolatey `
    -requiredVariable packageConfigPath `
{
    exec { & $chocolateyBin install $packageConfigPath -y }
}

Task InstallChocolateyPackage `
    -description 'Installs a package using the Chocolatey package manager.' `
    -depends EnsureChocolatey `
    -requiredVariables chocolateyPackageId `
{
    if (-not $ChocolateyPackageVersion) {
        Write-Output "Installing package $chocolateyPackageId from the Chocolatey package repository..."
        exec { & $chocolateyBin install $chocolateyPackageId -y }
    } else {
        Write-Output "Installing package $chocolateyPackageId version $chocolateyPackageVersion from the Chocolatey package repository..."
        exec { & $chocolateyBin install $chocolateyPackageId -Version $chocolateyPackageVersion -y }
    }
}

Task EnsureChocolatey -requiredVariables chocolateyBin `
    -description 'Ensures that the Chocolatey package manager is installed on the system. The installer is downloaded from https://chocolatey.org if required.' `
{
    Write-Output "Ensuring the Chocolatey package manager is installed..."

    $chocInstalled = Test-Path "$chocolateyBin"
    if (-not $chocInstalled) {
        Write-Output "Chocolatey not found, installing..."

        $installPs1 = ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
        Invoke-Expression $installPs1

        Write-Output "Chocolatey installation complete."
		throw "You MUST restart Powershell and retry for Chocolatey to work properly"
    } else {
        Write-Output "Chocolatey was found at $chocolateyBin and won't be reinstalled."
    }
}