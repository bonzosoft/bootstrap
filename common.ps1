#!/usr/bin/env pwsh


Write-Host "Loading '$PSCommandPath'."


$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest



[IO.DirectoryInfo]$Script:WORKINGDIR = (Get-Location).Path
write-host $Script:WORKINGDIR

# project information
[string]$Script:PROJECTNAME          = $Script:WORKINGDIR.BaseName
[int]$Script:PUID                    = 568
[int]$Script:PGID                    = 568

# project directory structure
[string]$Script:CONFIGDIRNAME        = "config"
[IO.DirectoryInfo]$Script:CONFIGDIR  = Join-Path -Path $Script:WORKINGDIR -ChildPath $Script:CONFIGDIRNAME
[IO.DirectoryInfo]$Script:INCLUDEDIR = Join-Path -Path $Script:WORKINGDIR -ChildPath $IncludeDirName
[IO.FileInfo]$Script:COMPOSEFILE     = Join-Path -Path $Script:WORKINGDIR -ChildPath "compose.yaml"
[IO.FileInfo]$Script:ENVFILE         = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env"

# data directory structure
[IO.DirectoryInfo]$Script:DATADIR    = Join-Path -Path $Script:WORKINGDIR.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:PROJECTNAME
[IO.DirectoryInfo]$Script:SECRETSDIR = Join-Path -Path $Script:DATADIR -ChildPath ".secrets"

# infra directory structure
[IO.FileInfo]$Script:CONFIGJSON      = Join-Path -Path $Script:WORKINGDIR.Parent -ChildPath ".docker.config.json"
if (Test-Path -Path $Script:CONFIGJSON) {
    $Script:DOCKERCONFIG  = Get-Content -Path $Script:CONFIGJSON | ConvertFrom-Json
}
else {
    throw "File '$($Script:CONFIGJSON)' not found."
}