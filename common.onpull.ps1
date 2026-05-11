#!/usr/bin/env pwsh

### SINGLETON ##################################################################
$singleton = ([IO.FileInfo]$PSCommandPath).BaseName.Replace(".","_").ToUpper()
if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
}
Write-Information -Message "Loading script '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


## SELECT REALM ################################################################
Switch-DockerRealm


## PULL SUBMODULES #############################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    Write-Information -Message "Pulling submodules."
    $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
    if ($LASTEXITCODE) {
        throw ($errorVariable | Out-String)
    }
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Name PUID             -Value $Script:Context.PUID
Set-DockerVariable -Name PGID             -Value $Script:Context.PGID
Set-DockerVariable -Name DATADIR          -Value $Script:Context.DataDir.FullName
Set-DockerVariable -Name INCLUDEDIR       -Value $Script:Context.IncludeDir.FullName
Set-DockerVariable -Name SECRETSDIR       -Value $Script:Context.SecretsDir.FullName
Set-DockerVariable -Name SOCKETPROXY_PGID -Value (Get-DockerGid) -NoAppend


## GET SERVICES INFORMATION ####################################################
Write-Information -Message $Script:Context
$compose = Get-DockerCompose -Path $Script:Context.ComposeFile
$volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys
Set-DockerContext -Name Service -Value $volumes
Write-Information -Message $Script:Context


## LOAD SUBMODULES SCRIPTS #####################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    foreach ($script in (Get-Item -Path (Join-Path -Path $Script:Context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))) {
        Write-Information -Message "Loading submodule script '$($script.FullName)'."
        . $script.FullName
    }
}

## SET STORAGE PERMISSION ######################################################
foreach ($service in $Script:Context.Service.Keys) {
    if ($Script:Context.Service.$service.Volume) {
        Write-Information -Message "Configuring storage for service $($service)"
        Grant-DockerPermission `
            -Path $Script:Context.Service.$service.Volume `
            -PUID $Script:Context.Service.$service.PUID `
            -PGID $Script:Context.Service.$service.PGID `
            -Permission "0755" `
            -Recurse `
            -Force
    }
}


Write-Information -Message "Loaded script '$PSCommandPath'."
