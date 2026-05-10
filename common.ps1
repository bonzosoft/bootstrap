#!/usr/bin/env pwsh


### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON" -Scope Global -Value $true
}


Write-Information -Message "Loading script '$PSCommandPath'."


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")


### LOAD CONTEXT ###############################################################
Set-DockerContext -Name WorkingDir       -Value ([IO.DirectoryInfo](Get-Location).Path)
Set-DockerContext -Name ConfigDir        -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "config"))
Set-DockerContext -Name IncludeDir       -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "include"))
Set-DockerContext -Name ComposeFile      -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "compose.yaml"))
Set-DockerContext -Name DotEnvFile       -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath ".env"))

Set-DockerContext -Name ProjectName      -Value ([string]$Script:Context.WorkingDir.BaseName)
Set-DockerContext -Name DataDir          -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:Context.ProjectName))
Set-DockerContext -Name SecretsDir       -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.DataDir -ChildPath ".secrets"))

Set-DockerContext -Name HostInfo         -Value (Get-Content -Path (Join-Path -Path $Script:Context.WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json)

Set-DockerContext -Name APP_PUID         -Value 568
Set-DockerContext -Name APP_PGID         -Value 568
Set-DockerContext -Name WEBPROXY_PUID    -Value $Script:Context.APP_PUID
Set-DockerContext -Name WEBPROXY_PGID    -Value $Script:Context.APP_PGID
Set-DockerContext -Name DB_PUID          -Value $Script:Context.APP_PUID
Set-DockerContext -Name DB_PGID          -Value $Script:Context.APP_PGID
Set-DockerContext -Name DBBACKUP_PUID    -Value 0
Set-DockerContext -Name DBBACKUP_PGID    -Value $Script:Context.APP_PGID
Set-DockerContext -Name SOCKETPROXY_PUID -Value $Script:Context.APP_PUID
Set-DockerContext -Name SOCKETPROXY_PGID -Value $(Get-DockerGid)
Set-DockerContext -Name WORKER_PUID      -Value $Script:Context.APP_PUID
Set-DockerContext -Name WORKER_PGID      -Value $Script:Context.APP_PGID
Set-DockerContext -Name HOST_HOSTNAME    -Value $(Get-DockerHostname)


Write-Information -Message "Loaded script '$PSCommandPath'."
