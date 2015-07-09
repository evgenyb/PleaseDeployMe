Properties {
    $nugetBin = (Get-Command nuget).Path
    $packageConfigPath = "$buildDir\nuget\packages.config"

    # The ID of an application package. Required. Example: nunit.
    $nugetPackageId = $null

    # If a specific version of the package is required enter it here.
    # Otherwise, leave this field blank to use the latest version. Example: 2.3.4.
    $nugetPackageVersion = $null
}

Task default

Task InstallNugetPackages `
    -description 'Installs all NuGet packages in the config file.' `
    -requiredVariable packageConfigPath, nugetPackagesDir `
{
    exec { & $nugetBin restore $packageConfigPath -PackagesDirectory $nugetPackagesDir }
}

Task RestoreNugetPackages `
    -description 'Restores all NuGet packages for the solution.' `
    -requiredVariable solutionPath `
{
    exec { & $nugetBin restore $solutionPath }
}

Task InstallNugetPackage `
    -description 'Installs a package using the NuGet package manager.' `
    -requiredVariables nugetPackageId, nugetPackagesDir `
{
    if (-not $nugetPackageVersion) {
        Write-Output "Installing package $nugetPackageId from the NuGet package repository..."
        exec { & $nugetBin install $nugetPackageId -PackagesDirectory $nugetPackagesDir }
    } else {
        Write-Output "Installing package $nugetPackageId version $nugetPackageVersion from the NuGet package repository..."
        exec { & $nugetBin install $nugetPackageId -Version $nugetPackageVersion -PackagesDirectory $nugetPackagesDir }
    }
}