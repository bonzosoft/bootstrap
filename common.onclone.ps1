Write-Host "Loading $PSCommandPath"


## COMMON SCRIPT ###############################################################



## SET .env FILE ACCORDING TO REALM
[IO.FileInfo]$realmDotEnvFile = Join-Path -Path $Script:WORKINGDIR -ChildPath "./.env.$Realm"
if (Test-Path -Path $realmDotEnvFile) {
    New-Item -Path $workingDotEnvFile -ItemType SymbolicLink -Value $realmDotEnvFile -Force | Out-Null
}

## SET COMMON .env VARIABLES
Set-DockerVariable -Path $workingDotEnvFile -Name DATADIR    -Value $Script:DataDir.FullName    -Overwrite -Force
#Set-DockerVariable -Path $workingDotEnvFile -Name CONFIGDIR  -Value $Script:ConfigDir.FullName  -Overwrite -Force
Set-DockerVariable -Path $workingDotEnvFile -Name INCLUDEDIR -Value $Script:IncludeDir.FullName -Overwrite -Force
Set-DockerVariable -Path $workingDotEnvFile -Name SECRETSDIR -Value $Script:SecretsDir.FullName -Overwrite -Force


if (Test-Path -Path $Script:IncludeDir) {
    ## UPDATE SUBMODULES
    if ($IsLinux) {
        Write-Host "Updating submodules."
        git submodule update --init --recursive --depth 1
    }

    ## RUN INCLUDE SCRIPTS
    [IO.FileSystemInfo]$scripts = Get-Item -Path $Script:IncludeDir -Filter "*/onclone.ps1"
    $scripts
    foreach ($script in $scripts) {
        Write-Host "Loading submodule script '$($script.FullName)'."
        #. $script.FullName
    }
}
else {
    Write-Host "No submodule find."
}

Write-Host "Finishing $PSCommandPath"