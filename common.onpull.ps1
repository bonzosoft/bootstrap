Write-Host "Loading $PSCommandPath"


### Configuration ##############################################################
Set-StrictMode -Version Latest


### Load module ################################################################
Import-Module -Name (Path-Join -Path $PSScriptRoot -ChildPath "posh-Docker") #-ArgumentList $ENTRYSCRIPT


### Script #####################################################################

## SELECT ENV FILE BASED ON REALM
[IO.FileInfo]$currentEnvFile = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env.$Realm"
if (Test-Path -Path $currentEnvFile) {
    New-Item -Path $Script:ENVFILE -ItemType SymbolicLink -Value $currentEnvFile -Force | Out-Null
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Path $ENVFILE -Name DATADIR    -Value $Script:DATADIR.FullName    -Overwrite -Append -Force
#Set-DockerVariable -Path $ENVFILE -Name CONFIGDIR  -Value $Script:CONFIGDIR.FullName  -Overwrite -Append -Force
Set-DockerVariable -Path $ENVFILE -Name INCLUDEDIR -Value $Script:INCLUDEDIR.FullName -Overwrite -Append -Force
Set-DockerVariable -Path $ENVFILE -Name SECRETSDIR -Value $Script:SECRETSDIR.FullName -Overwrite -Append -Force


## SUBMODULES MANAGEMENT
if (Test-Path -Path $Script:INCLUDEDIR) {
    ## UPDATE SUBMODULE
    Write-Host "Updating submodules."
    if ($IsLinux) {
        git submodule update --init --recursive --depth 1 2>$null
    }

    ## LOAD SUBMODULE SCRIPTS
    [Collections.Generic.List[IO.FileInfo]]$submodulesScriptsList = Get-Item -Path (Join-Path -Path $Script:INCLUDEDIR -ChildPath "*/$($ENTRYSCRIPT.Name)")
    foreach ($script in $submodulesScriptsList) {
        Write-Host "Loading submodule script '$($script.FullName)'."
        . $script.FullName
    }
}


## Set file permisisons for volumes
[Collections.Generic.List[IO.FileSystemInfo]]$volumes= Get-DockerVolumes -Data (Get-DockerCompose -Path $Script:COMPOSEFILE)
foreach ($volume in $volumes) {
    Grant-DockerPermission -Path $volume -PUID $Script:PUID -PGID $Script:PGID -Mode 0755 -Recurse -Force
}

Write-Host "Finishing $PSCommandPath"
