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


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")


### LOAD CONTEXT ###############################################################
$WorkingDir = [IO.DirectoryInfo](Get-Location).Path
$CommonDir = [IO.DirectoryInfo]([IO.FileInfo]$PSCommandPath).Directory

$Script:Context = @{
    "WorkingDir" =  $WorkingDir
    "CommonDir"  =  $CommonDir
    "IncludeDir" =  [IO.DirectoryInfo](Join-Path -Path $WorkingDir -ChildPath "include")
    "DataDir" =     [IO.DirectoryInfo](Join-Path -Path $WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $WorkingDir.BaseName))
    "SecretsDir" =  [IO.DirectoryInfo](Join-Path -Path $WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $WorkingDir.BaseName, ".secrets"))
    "ComposeFile" = [IO.FileInfo](Join-Path -Path $WorkingDir -ChildPath "compose.yaml")
    "DotEnvFile" =  [IO.FileInfo](Join-Path -Path $WorkingDir -ChildPath ".env")
    "ConfigFile" =  [IO.FileInfo](Join-Path -Path $WorkingDir.Parent -ChildPath "" -AdditionalChildPath @(".config", "docker.config.json"))
    "Hostname" =    [string](Get-DockerHostname)
    "Tenant" =      (Get-Content -Path (Join-Path -Path $WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json).TENANT
    "Docker" = @{
        "ProjectName"=  [string]($WorkingDir.BaseName)
        "PUID" =        [int]568
        "PGID" =        [int]568
        "DockerPGID" =  [int](Get-DockerPGID)
    }
}

$tenantData = Join-Path -Path $Script:Context.CommonDir -ChildPath "tenants" -AdditionalChildPath "$($Script:Context.Tenant).json"
$Script:Context += Get-Content -Path $tenantData -Encoding utf8  ConvertFrom-Json -AsHashTable
Write-Information "Tracing:`n$($Script:Context | Out-String)"


Write-Information -Message "Loaded script '$PSCommandPath'."
