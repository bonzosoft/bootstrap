#!/usr/bin/env pwsh


### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON" -Scope Global -Value $true
}


Write-Verbose -Verbose "Loading '$PSCommandPath'."


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")


### LOAD CONTEXT ###############################################################
$Script:Context = Import-DockerContext


Write-Verbose -Message "Finishing '$PSCommandPath'."
