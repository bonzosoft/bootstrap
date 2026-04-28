#!/usr/bin/env pwsh


Write-Host "Loading '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


################################################################################
### BELOW HERE TO BE RUN AFTER COMMON ASSETS ###################################
################################################################################


## SELECT ENV FILE BASED ON REALM
[IO.FileInfo]$sourceEnvFile = Join-Path -Path $Script:WorkingDir -ChildPath ".env.$($Script:Config.REALM)"
if (Test-Path -Path $sourceEnvFile) {
    New-Item -Path $Script:EnvFile -ItemType SymbolicLink -Value $sourceEnvFile -Force | Out-Null
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Path $ENVFILE -Name DATADIR    -Value $Script:DataDir.FullName    -Force
#Set-DockerVariable -Path $ENVFILE -Name CONFIGDIR  -Value $Script:ConfigDir.FullName -Force
Set-DockerVariable -Path $ENVFILE -Name INCLUDEDIR -Value $Script:IncludeDir.FullName -Force
Set-DockerVariable -Path $ENVFILE -Name SECRETSDIR -Value $Script:SecretsDir.FullName -Force


## SUBMODULES MANAGEMENT
if (Test-Path -Path $Script:IncludeDir) {
    ## UPDATE SUBMODULE
    Write-Host "Pulling submodules."
    if ($IsLinux) {
        git submodule update --init --recursive --depth 1 2>$null
    }

    ## LOAD SUBMODULE SCRIPTS
    Write-Host "Loading submodule scripts."
    [IO.FileInfo[]]$submoduleScripts = @(Get-Item -Path (Join-Path -Path $Script:IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))
    foreach ($script in $submoduleScripts) {
        Write-Host "Running submodule script '$($script.FullName)'."
        . $script.FullName
    }
}

## Set file permisisons for volumes
[IO.FileSystemInfo[]]$volumes= Get-DockerVolumes -Data (Get-DockerCompose -Path $Script:COMPOSEFILE)
#foreach ($volume in $volumes) {
    Grant-DockerPermission -Path $volumes -PUID $Script:PUID -PGID $Script:PGID -Mode "0755" -Recurse -Force
#}


Write-Host "Finishing '$PSCommandPath'."
