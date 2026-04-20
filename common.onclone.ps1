Write-Host "Loading $PSCommandPath"


## COMMON SCRIPT ###############################################################



## SET .env FILE ACCORDING TO REALM
[IO.FileInfo]$realmDotEnvFile = Join-Path -Path $Script:WORKINGDIR -ChildPath "./.env.$Realm"
if (Test-Path -Path $realmDotEnvFile) {
    New-Item -Path $Script:workingDotEnvFile -ItemType SymbolicLink -Value $realmDotEnvFile -Force | Out-Null
}

## SET COMMON .env VARIABLES
Set-DockerVariable -Path $workingDotEnvFile -Name DATADIR    -Value $Script:DataDir.FullName    -Overwrite -Force
#Set-DockerVariable -Path $workingDotEnvFile -Name CONFIGDIR  -Value $Script:ConfigDir.FullName  -Overwrite -Force
Set-DockerVariable -Path $workingDotEnvFile -Name INCLUDEDIR -Value $Script:IncludeDir.FullName -Overwrite -Force
Set-DockerVariable -Path $workingDotEnvFile -Name SECRETSDIR -Value $Script:SecretsDir.FullName -Overwrite -Force

## SUBMODULES MANIPULATION
if (Test-Path -Path $Script:IncludeDir) {
    ## UPDATE SUBMODULES
    if ($IsLinux) {
        Write-Information "Updating submodules."
        git submodule update --init --recursive --depth 1
    }

    ## RUN SUBMODULE SCRIPTS
    [IO.FileSystemInfo]$scripts = Get-Item -Path (Join-Path -Path $Script:IncludeDir -ChildPath "*/onclone.ps1")
    foreach ($script in $scripts) {
        Write-Information "Loading submodule script '$($script.FullName)'."
        . $script.FullName
    }
}
else {
    Write-Information "No submodule find."
}

## Set file permisisons for volumes
[hashtable]$compose = Get-DockerCompose -Path $Script:workingComposeFile
$compose
$compose.services
$compose.services.app 
$compose.services.app.volumes
$compose.services.app.volumes.source
[string[]]$volumes = Get-DockerVolumes $compose
$volumes

Write-Information "Finishing $PSCommandPath"