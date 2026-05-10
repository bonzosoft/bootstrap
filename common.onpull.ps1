#!/usr/bin/env pwsh


### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON_ONPULL" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON_ONPULL" -Scope Global -Value $true
}


Write-Information -Message "Loading script '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


## SET ENV FILE VARIABLES
Switch-DockerRealm
Set-DockerVariable -Name DATADIR    -Value $Script:Context.DataDir.FullName
Set-DockerVariable -Name INCLUDEDIR -Value $Script:Context.IncludeDir.FullName
Set-DockerVariable -Name SECRETSDIR -Value $Script:Context.SecretsDir.FullName
$Script:Context


## SUBMODULES MANAGEMENT
if (Test-Path -Path $Script:Context.IncludeDir) {
    ## UPDATE SUBMODULE
    Write-Information -Message "Pulling submodules."
    if ($IsLinux) {
        git submodule update --init --recursive --depth 1 2>$null
    }

    ## LOAD SUBMODULE SCRIPTS
    Write-Host "Loading submodule scripts."
    [IO.FileInfo[]]$submoduleScripts = Get-Item -Path (Join-Path -Path $Script:Context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf))
    foreach ($script in $submoduleScripts) {
        Write-Information -Message "Running submodule script '$($script.FullName)'."
        . $script.FullName
    }
}

## Set file permisisons for volumes
$volumes = Get-DockerVolumes -Data (Get-DockerCompose -Path $Script:Context.ComposeFile)
foreach ($service in $volumes.PSObject.Properties.Name) {
    Write-Information -Message "Configuring storage for service $service"
    $puidName = "$($service.ToUpper())_PUID"
    $pgidName = "$($service.ToUpper())_PGID"
    $volumes.$service.FullName
    Grant-DockerPermission -Path $volumes.$service -PUID $Script:Context.$puidName -PGID $Script:Context.$pgidName -Permission "0755" -Recurse -Force
}



Write-Information -Message "Loaded script '$PSCommandPath'."
