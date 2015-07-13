# Create new Database
Properties {
    $executeRemotely = $false
    # Database connection string
    $connectionString = $null
    # The database name
    $databaseName = $null
    # Full path where scripts are located
    $installationDirectoryPath = $null
    # Username (only used when $executeRemotely is $true)
    $username = $null
    # Password (only used when $executeRemotely is $true)
    $password = $null
}

Task Default -depends MigrateDatabase

Task MigrateDatabase {
    Validate-Parameter $connectionString -parameterName "Connection string"
    Validate-Parameter $installationDirectoryPath -parameterName "Installation directory path"
    Validate-Parameter $username -parameterName "Username"
    Validate-Parameter $password -parameterName "Password"
    Validate-Parameter $databaseName -parameterName "Database name"

    $roundhouse_exe_path = "$installationDirectoryPath\rh.exe"
    $scripts_dir = "$installationDirectoryPath\Scripts"
    $roundhouse_output_dir = "$installationDirectoryPath\output"
    $createDbScript = "$scripts_dir\CreateDB\CreateDatabase.sql"
    $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
    $credential =  New-Object -typename System.Management.Automation.PSCredential -ArgumentList $username, $securePassword

    if ($executeRemotely -eq $false) {
        Write-Host "Running in local mode"
        exec { & $roundhouse_exe_path -d $databaseName -c $connectionString -f $scripts_dir -cds $createDbScript -o $roundhouse_output_dir --silent }
    } else {
        Write-Host "Running in remote mode"
        Invoke-Command -Credential $credential -ComputerName $env:ComputerName -Authentication Credssp -ArgumentList $roundhouse_exe_path, $databaseName, $connectionString, $scripts_dir, $roundhouse_output_dir, $createDbScript -ScriptBlock {
            param($roundhouse_exe_path, $databaseName, $connectionString, $scripts_dir, $roundhouse_output_dir, $createDbScript)
            $params = @("-d", "$databaseName", "-c", "$connectionString", "-f", "$scripts_dir", "-o", "$roundhouse_output_dir","-cds", $createDbScript , "--env", "OCTOPUS", "--silent")
    
            & $roundhouse_exe_path $params
    
            if ($LastExitCode -ne 0)
            {        
                throw "Database deployment failed !!"
                exit 1
            }
            exit 0
        }
    }
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
