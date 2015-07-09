# Create an IIS virtual application (a virtual directory with an application pool)

properties {
    # Virtual path
    # The name of the application to create. For example, to serve an application that will be available at /myapp, enter myapp. To create an application under a parent virtual directory or application, separate with slashes - for example: /applications/myapp
    $virtualPath = $null

    # Physical path
    # Physical folder that the application will serve files from. Example: C:\MyApp.
    $physicalPath = $null

    # Application pool
    # The name of the application pool that the application will run under. The application pool must already exist.
    $applicationPoolName = $null

    # Parent site
    # The name of the IIS web site to attach the application to. For example, to put the application under the default web site, use 'Default Web Site'
    $parentSite = "Default Web Site"
}

Task Default -depends CreateApplication

Task CreateApplication `
    -requiredVariables virtualPath, physicalPath, applicationPoolName `
{

    Validate-Parameter $virtualPath -parameterName "Virtual path"
    Validate-Parameter $physicalPath -parameterName "Physical path"
    Validate-Parameter $applicationPoolName -parameterName "Application pool"
    Validate-Parameter $parentSite -parameterName "Parent site"

    #Load Web Admin DLL
    #[System.Reflection.Assembly]::LoadFrom( "C:\windows\system32\inetsrv\Microsoft.Web.Administration.dll" )

    Add-PSSnapin WebAdministration -ErrorAction SilentlyContinue
    Import-Module WebAdministration -ErrorAction SilentlyContinue

    ## --------------------------------------------------------------------------------------
    ## Run
    ## --------------------------------------------------------------------------------------

    Write-Host "Getting web site $parentSite"
    $site = Get-Website -name $parentSite
    if (!$site) {
        throw "The web site '$parentSite' does not exist. Please create the site first."
    }

    $parts = $virtualPath -split "[/\\]"
    $name = ""

    for ($i = 0; $i -lt $parts.Length; $i++) {
        $name = $name + "/" + $parts[$i]
        $name = $name.TrimStart('/').TrimEnd('/')
        if ($i -eq $parts.Length - 1) {

        }
        elseif ([string]::IsNullOrEmpty($name) -eq $false -and $name -ne "/") {
            Write-Host "Ensuring parent exists: $name"

            $app = Get-WebApplication -Name $name -Site $parentSite

            if (!$app) {
                $vdir = Get-WebVirtualDirectory -Name $name -site $parentSite
                if (!$vdir) {
                    throw "The application or virtual directory '$name' does not exist"
                }
            }
        }
    }

    $existing = Get-WebApplication -site $parentSite -Name $name

    Execute-WithRetry {
        if (!$existing) {
            Write-Host "Creating web application '$name'"
            New-WebApplication -Site $parentSite -Name $name -ApplicationPool $applicationPoolName -PhysicalPath $physicalPath
            Write-Host "Web application created" -ForegroundColor Green
        } else {
            Write-Host "The web application '$name' already exists. Updating physical path:" -ForegroundColor Green

            Set-ItemProperty IIS:\Sites\$parentSite\$name -name physicalPath -value $physicalPath

            Write-Host "Physical path changed to: $physicalPath" -ForegroundColor Green
        }
    }
}

## --------------------------------------------------------------------------------------
## Helpers
## --------------------------------------------------------------------------------------
# Helper for validating input parameters
function Validate-Parameter([string]$foo, [string[]]$validInput, $parameterName) {
    Write-Host "${parameterName}: $foo"
    if (! $foo) {
        throw "No value was set for $parameterName, and it cannot be empty"
    }

    if ($validInput) {
        if (! $validInput -contains $foo) {
            throw "'$input' is not a valid input for '$parameterName'"
        }
    }

}

# Helper to run a block with a retry if things go wrong
$maxFailures = 5
$sleepBetweenFailures = Get-Random -minimum 1 -maximum 4
function Execute-WithRetry([ScriptBlock] $command) {
    $attemptCount = 0
    $operationIncomplete = $true

    while ($operationIncomplete -and $attemptCount -lt $maxFailures) {
        $attemptCount = ($attemptCount + 1)

        if ($attemptCount -ge 2) {
            Write-Output "Waiting for $sleepBetweenFailures seconds before retrying..."
            Start-Sleep -s $sleepBetweenFailures
            Write-Output "Retrying..."
        }

        try {
            & $command

            $operationIncomplete = $false
        } catch [System.Exception] {
            if ($attemptCount -lt ($maxFailures)) {
                Write-Output ("Attempt $attemptCount of $maxFailures failed: " + $_.Exception.Message)

            }
            else {
                throw "Failed to execute command"
            }
        }
    }
}