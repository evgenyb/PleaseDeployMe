# Create new Database
Properties {
    $connectionString = $null
    $installationDirectoryPath = $null
    $username = $null
    $password = $null
}

$roundhouse_exe_path = $installationDirectoryPath + "\rh.exe"
$scripts_dir = $installationDirectoryPath + "\Scripts"
$roundhouse_output_dir = $installationDirectoryPath + "\output"
$createDbScript = $scripts_dir + "\CreateDB\CreateDatabase.sql"

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$credential =  New-Object -typename System.Management.Automation.PSCredential -ArgumentList $username, $securePassword

Invoke-Command -Credential $credential -ComputerName $env:ComputerName -Authentication Credssp -ArgumentList $roundhouse_exe_path, $connectionString, $scripts_dir, $roundhouse_output_dir, $createDbScript -ScriptBlock {
    param($roundhouse_exe_path, $connectionString, $scripts_dir, $roundhouse_output_dir, $createDbScript)
    $params = @("-c", "$connectionString", "-f", "$scripts_dir", "-o", "$roundhouse_output_dir","-cds", $createDbScript , "--env", "OCTOPUS", "--silent")

    & $roundhouse_exe_path $params

    if ($LastExitCode -ne 0)
    {        
        throw "database deployment failed !!"
        exit 1
    }
    exit 0
}