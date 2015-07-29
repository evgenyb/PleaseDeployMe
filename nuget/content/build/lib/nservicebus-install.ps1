Properties {
    # Full path where the service was deployed
    $installationDirectoryPath = $null #$OctopusParameters['OctopusOriginalPackageDirectoryPath']
    $serviceName = $null # $OctopusParameters['NServiceBus.ServiceName']    
    $username = $null # $OctopusParameters['Application.Owner.Username']
    $password = $null # $OctopusParameters['Application.Owner.Password']
}

Task Default -depends InstallNServiceBus

Task InstallNServiceBus {
    Validate-Parameter $installationDirectoryPath -parameterName "Installation Directory Path"
    Validate-Parameter $serviceName -parameterName "Windows Service name"
    Validate-Parameter $username -parameterName "Username"
    Validate-Parameter $password -parameterName "Password"

    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $credential =  New-Object -typename System.Management.Automation.PSCredential -ArgumentList $username, $securePassword

    $NServiceBusPath = Join-Path $installationDirectoryPath 'NServiceBus.Host.exe'
    Write-Host "Service $serviceName is deployed to $installationDirectoryPath" -ForegroundColor Green
    Enable-LocalWSManCredSSP
    
    Write-Host "Uninstalling service $serviceName..." -ForegroundColor Green
    & $NServiceBusPath @("/uninstall", "/serviceName:$serviceName")
    if ($LastExitCode -ne 0)
    {        
        throw "Uninstall failed !!"
        exit 1
    }

    Write-Host "Installing service $serviceName..." -ForegroundColor Green
    & $NServiceBusPath @("/install", "NServiceBus.Production", "/serviceName:$serviceName", "/displayName:$serviceName", "/description:$serviceName", "/username:$username", "/password:$password")
    if ($LastExitCode -ne 0)
    {        
        throw "Install of NServiceBus failed !!"
        exit 1
    }

    Write-Host "Starting service $serviceName..." -ForegroundColor Green
    Start-Service $serviceName
}

Task UninstallNServiceBus {
    Validate-Parameter $installationDirectoryPath -parameterName "Installation Directory Path"
    Validate-Parameter $serviceName -parameterName "Windows Service name"


    $NServiceBusPath = Join-Path $installationDirectoryPath 'NServiceBus.Host.exe'
    Write-Host "Service $serviceName is deployed to $installationDirectoryPath" -ForegroundColor Green
    Enable-LocalWSManCredSSP
    
    Write-Host "Uninstalling service $serviceName..." -ForegroundColor Green
    & $NServiceBusPath @("/uninstall", "/serviceName:$serviceName")
    if ($LastExitCode -ne 0)
    {        
        throw "Uninstall failed !!"
        exit 1
    }
}

<#
.Synopsis
Enabeling CredSSP client and server on the same computer is necessary in order to properly install NServiceBus.
The Octopus Tentacle might be running as LocalService, and the NServiceBus service must be installed using a specific username and password. 
Currently, this is accomplished using Invoke-Command with -Authentication  CredSSP and -Computer $env:Computer. 
#>
Function Enable-LocalWSManCredSSP
{
    [String]$ComputerFCDN = ([System.Net.Dns]::GetHostEntry($env:computername).HostName)
    $CredRegpath = "HKLM:\software\policies\microsoft\windows\CredentialsDelegation\AllowFreshCredentials"

    # Enable Credential Security Support Provider (CredSSP) authentication server role.
    if (((Get-Item WSMan:\LocalHost\Service\Auth\CredSSP).Value) -eq "false")
    {
        Write-Output ( "Enabeling CredSSP Server role on {0}" -f  $ComputerFCDN )
        Enable-WSManCredSSP -Role Server -Force
    }
    else 
    {
        Write-Output ( "CredSSP Server role already ready on {0}" -f  $ComputerFCDN )
    }


    $AllowedComputers = Get-Item $CredRegpath -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty property |
            % { (Get-ItemProperty -Path $CredRegpath -Name $_).$_ } 

    # Enable Credential Security Support Provider (CredSSP) authentication client role.
    if( ! ($AllowedComputers | Where-Object { $_ -match $ComputerFCDN }))
    {
        Write-Output ( "Enabeling CredSSP Client role on {0}" -f  $ComputerFCDN )
        Enable-WSManCredSSP -Role Client -DelegateComputer $ComputerFCDN  -Force
    }
    else
    {
        Write-Output ( "CredSSP Client role already ready on {0}" -f  $ComputerFCDN )
    }


    Write-Output "Configured as client for servers:"
    $AllowedComputers | ForEach-Object { Write-Output ( "`t{0}" -f  $_ ) }

}

