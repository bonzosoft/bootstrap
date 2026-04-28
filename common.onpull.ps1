#!/usr/bin/env pwsh

### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON_ONPULL" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON_ONPULL" -Scope Global -Value $true
}


Write-Host "Loading '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


## SET ENV FILE
[IO.FileInfo]$sourceEnvFile = Join-Path -Path $Script:Context.WorkingDir -ChildPath ".env.$($Script:Context.HostInfo.REALM)"
if (Test-Path -Path $sourceEnvFile) {
    New-Item -Path $Script:EnvFile -ItemType SymbolicLink -Value $sourceEnvFile -Force | Out-Null
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Name DATADIR    -Value $Script:Context.DataDir.FullName    -Force
#Set-DockerVariable -Name CONFIGDIR  -Value $Script:Context.ConfigDir.FullName -Force
Set-DockerVariable -Name INCLUDEDIR -Value $Script:Context.IncludeDir.FullName -Force
Set-DockerVariable -Name SECRETSDIR -Value $Script:Context.SecretsDir.FullName -Force


## SUBMODULES MANAGEMENT
if (Test-Path -Path $Script:Context.IncludeDir) {
    ## UPDATE SUBMODULE
    Write-Host "Pulling submodules."
    if ($IsLinux) {
        git submodule update --init --recursive --depth 1 2>$null
    }

    ## LOAD SUBMODULE SCRIPTS
    Write-Host "Loading submodule scripts."
    [IO.FileInfo[]]$submoduleScripts = @(Get-Item -Path (Join-Path -Path $Script:Context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))
    foreach ($script in $submoduleScripts) {
        Write-Host "Running submodule script '$($script.FullName)'."
        . $script.FullName
    }
}

## Set file permisisons for volumes
[IO.FileSystemInfo[]]$volumes = Get-DockerVolumes -Data (Get-DockerCompose -Path $Script:Context.ComposeFile)
Grant-DockerPermission -Path $volumes -PUID $Script:Context.PUID -PGID $Script:Context.PGID -Permission "0755" -Recurse -Force



Write-Host "Finishing '$PSCommandPath'."
