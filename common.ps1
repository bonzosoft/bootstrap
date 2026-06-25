#!/usr/bin/env pwsh

### SINGLETON ##################################################################
$singleton = ([IO.FileInfo]$PSCommandPath).BaseName.Replace(".","_").ToUpper()
if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
}
Write-Information -MessageData "Loading script '$PSCommandPath'."


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$VerbosePreference     = 'Continue'
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
$modules = @(
    "pwsh-Docker"
    "pwsh-Git"
)
$verboseBackup     = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
foreach ($module in $modules) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath @("modules", $module))
}
$VerbosePreference = $verboseBackup


### SETUP CONTEXT ##############################################################
$Script:Context = Get-DockerContext


Write-Information -MessageData "Loaded script '$PSCommandPath'."
