#!/usr/bin/env pwsh


Write-Host "Loading '$PSCommandPath'."


### CONFIGURATION ##############################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### VARIABLES ##################################################################

[IO.DirectoryInfo]$Script:WorkingDir = (Get-Location).Path

# project directory structure
[IO.DirectoryInfo]$Script:ConfigDir  = Join-Path -Path $Script:WorkingDir -ChildPath "config" #$ConfigDirName = Split-Path -Path $Script:ConfigDir -Leaf
[IO.DirectoryInfo]$Script:IncludeDir = Join-Path -Path $Script:WorkingDir -ChildPath "include"
[IO.FileInfo]$Script:ComposeFile     = Join-Path -Path $Script:WorkingDir -ChildPath "compose.yaml"
[IO.FileInfo]$Script:EnvFile         = Join-Path -Path $Script:WorkingDir -ChildPath ".env"

# data directory structure
[string]$Script:ProjectName          = $Script:WorkingDir.BaseName
[IO.DirectoryInfo]$Script:DataDir    = Join-Path -Path $Script:WorkingDir.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:ProjectName
[IO.DirectoryInfo]$Script:SecretsDir = Join-Path -Path $Script:DataDir -ChildPath ".secrets"

# infra directory structure
[IO.FileInfo]$jsonFile      = Join-Path -Path $Script:WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json"
if (Test-Path -Path $Script:jsonFile) {
    $Script:Config = Get-Content -Path $jsonFile | ConvertFrom-Json
}
else {
    throw "File '$($jsonFile)' not found."
}

[int]$Script:PUID                    = 568
[int]$Script:PGID                    = 568
[int]$Script:DOCKER_PGID             = $Script:Config.DOCKER_PGID


Write-Host "WorkingDir:`t$Script:WorkingDir"
Write-Host "DataDir:`t$Script:DataDir"


### Load module ################################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")
