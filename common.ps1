#!/usr/bin/env pwsh


### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON" -Scope Global -Value $true
}


Write-Information -Message "Loading '$PSCommandPath'."


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")


### LOAD CONTEXT ###############################################################
$Script:Context | Add-Member -MemberType NoteProperty -Name WorkingDir       -Value ([IO.DirectoryInfo](Get-Location).Path)
$Script:Context | Add-Member -MemberType NoteProperty -Name ConfigDir        -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "config"))
$Script:Context | Add-Member -MemberType NoteProperty -Name IncludeDir       -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "include"))
$Script:Context | Add-Member -MemberType NoteProperty -Name ComposeFile      -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "compose.yaml"))
$Script:Context | Add-Member -MemberType NoteProperty -Name DotEnvFile       -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath ".env"))

$Script:Context | Add-Member -MemberType NoteProperty -Name ProjectName      -Value ([string]$Script:Context.WorkingDir.BaseName)
$Script:Context | Add-Member -MemberType NoteProperty -Name DataDir          -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:Context.ProjectName))
$Script:Context | Add-Member -MemberType NoteProperty -Name SecretsDir       -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.DataDir -ChildPath ".secrets"))

$Script:Context | Add-Member -MemberType NoteProperty -Name HostInfo         -Value (Get-Content -Path (Join-Path -Path $Script:Context.WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json)

$Script:Context | Add-Member -MemberType NoteProperty -Name APP_PUID         -Value 568
$Script:Context | Add-Member -MemberType NoteProperty -Name APP_PGID         -Value 568
$Script:Context | Add-Member -MemberType NoteProperty -Name WEBPROXY_PUID    -Value $Script:Context.APP_PUID
$Script:Context | Add-Member -MemberType NoteProperty -Name WEBPROXY_PGID    -Value $Script:Context.APP_PGID
$Script:Context | Add-Member -MemberType NoteProperty -Name DB_PUID          -Value $Script:Context.APP_PUID
$Script:Context | Add-Member -MemberType NoteProperty -Name DB_PGID          -Value $Script:Context.APP_PGID
$Script:Context | Add-Member -MemberType NoteProperty -Name DBBACKUP_PUID    -Value 0
$Script:Context | Add-Member -MemberType NoteProperty -Name DBBACKUP_PGID    -Value $Script:Context.APP_PGID
$Script:Context | Add-Member -MemberType NoteProperty -Name SOCKETPROXY_PUID -Value $Script:Context.APP_PUID
$Script:Context | Add-Member -MemberType NoteProperty -Name SOCKETPROXY_PGID -Value $Script:Context.HostInfo.DOCKER_PGID
$Script:Context | Add-Member -MemberType NoteProperty -Name WORKER_PUID      -Value $Script:Context.APP_PUID
$Script:Context | Add-Member -MemberType NoteProperty -Name WORKER_PGID      -Value $Script:Context.APP_PGID

$Script:Context = Import-DockerContext


Write-Information -Message "Finishing '$PSCommandPath'."
