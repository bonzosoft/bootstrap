Write-Host "Loading $PSCommandPath"

Import-Module -Name "$PSScriptRoot/posh-Docker" -ArgumentList $ENTRYSCRIPT


## COMMON SCRIPT ###############################################################


## SET .env FILE ACCORDING TO REALM
[IO.FileInfo]$realmDotEnvFile = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env.$Realm"
if (Test-Path -Path $realmDotEnvFile) {
    New-Item -Path $Script:ENVFILE -ItemType SymbolicLink -Value $realmDotEnvFile -Force | Out-Null
}


## SET COMMON .env VARIABLES
Set-DockerVariable -Path $ENVFILE -Name DATADIR    -Value $Script:DATADIR.FullName    -Overwrite -Force
#Set-DockerVariable -Path $ENVFILE -Name CONFIGDIR  -Value $Script:CONFIGDIR.FullName  -Overwrite -Force
Set-DockerVariable -Path $ENVFILE -Name INCLUDEDIR -Value $Script:INCLUDEDIR.FullName -Overwrite -Force
Set-DockerVariable -Path $ENVFILE -Name SECRETSDIR -Value $Script:SECRETSDIR.FullName -Overwrite -Force


## SUBMODULES MANIPULATION
if (Test-Path -Path $Script:INCLUDEDIR) {
    ## UPDATE SUBMODULES
    if ($IsLinux) {
        Write-Host "Updating submodules."
        git submodule update --init --recursive --depth 1 2>$null
    }

    ## RUN SUBMODULE SCRIPTS
    [IO.FileInfo]$scripts = Get-Item -Path (Join-Path -Path $Script:INCLUDEDIR -ChildPath "*/$($ENTRYSCRIPT.Name)")
    foreach ($script in $scripts) {
        Write-Host "Loading submodule script '$($script.FullName)'."
        . $script.FullName
    }
}


## Set file permisisons for volumes
[Collections.Generic.List[string]]$volumes = Get-DockerVolumes -Data (Get-DockerCompose -Path $Script:COMPOSEFILE)
foreach ($volume in $volumes) {
    $volume
    $volume.GetType()
    $volume | Format-List *
    Grant-DockerPermission -Path $volume.FullName -PUID $Script:PUID -PGID $Script:PGID -Mode 0755 -Recurse -Force
}

Write-Host "Finishing $PSCommandPath"
