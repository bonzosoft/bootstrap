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
$VerbosePreference = 'Continue'


### LOAD MODULES ###############################################################
$verboseBackup = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")
$VerbosePreference = $verboseBackup


### SETUP CONTEXT ##############################################################
$Script:Context = [ordered]@{}


$tenantData = Join-Path -Path $Script:Context.CommonDir -ChildPath "tenants" -AdditionalChildPath "$($Script:Context.Tenant).json"
$Script:Context += Get-Content -Path $tenantData -Encoding utf8 | ConvertFrom-Json -AsHashTable -Depth 9

Write-Verbose -Message ($Script:Context | Out-String)


Write-Information -Message "Loaded script '$PSCommandPath'."

