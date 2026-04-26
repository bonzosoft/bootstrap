#!/usr/bin/env pwsh


Write-Host "Loading '$PSCommandPath'."


### Configuration ##############################################################
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


### Load module ################################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker") #-ArgumentList $ENTRYSCRIPT


### Script #####################################################################

## SELECT ENV FILE BASED ON REALM
[IO.FileInfo]$currentEnvFile = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env.$($Script:REALM)"
if (Test-Path -Path $currentEnvFile) {
    New-Item -Path $Script:ENVFILE -ItemType SymbolicLink -Value $currentEnvFile -Force | Out-Null
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Path $ENVFILE -Name DATADIR    -Value $Script:DATADIR.FullName    -Force
#Set-DockerVariable -Path $ENVFILE -Name CONFIGDIR  -Value $Script:CONFIGDIR.FullName -Force
Set-DockerVariable -Path $ENVFILE -Name INCLUDEDIR -Value $Script:INCLUDEDIR.FullName -Force
Set-DockerVariable -Path $ENVFILE -Name SECRETSDIR -Value $Script:SECRETSDIR.FullName -Force


## SUBMODULES MANAGEMENT
if (Test-Path -Path $Script:INCLUDEDIR) {
    ## UPDATE SUBMODULE
    Write-Host "Updating submodules."
    if ($IsLinux) {
        git submodule update --init --recursive --depth 1 2>$null
    }

    ## LOAD SUBMODULE SCRIPTS
    Write-Host "Loading submodule scripts."
    [IO.FileInfo[]]$submodulesScriptsList = @(Get-Item -Path (Join-Path -Path $Script:INCLUDEDIR -ChildPath "*/$($Script:ENTRYSCRIPT.Name)"))
    foreach ($script in $submodulesScriptsList) {
        Write-Host "Running submodule script '$($script.FullName)'."
        . $script.FullName
    }
}


## Set file permisisons for volumes
#[Collections.Generic.List[IO.FileSystemInfo]]$volumes= Get-DockerVolumes -Data (Get-DockerCompose -Path $Script:COMPOSEFILE)
#foreach ($volume in $volumes) {
#    Grant-DockerPermission -Path $volume -PUID $Script:PUID -PGID $Script:PGID -Mode "0755" -Recurse -Force
#}

## Get Docker PGID
if (Test-Path -Path $Script:CONFIGJSON) {
    $configData = Get-Content -Path $Script:CONFIGJSON -Encoding utf8 | ConvertFrom-Json
}
Write-Host "Finishing '$PSCommandPath'."
