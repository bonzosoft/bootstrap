#!/usr/bin/env pwsh

### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON" -Scope Global -Value $true
}


Write-Host "Loading '$PSCommandPath'."


### CONFIGURATION ##############################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")


$Script:Environment = Get-DockerContext
Write-Host $Environment.WorkingDir
Write-Host $Environment.DotEnvFile
Write-Host $Environment.DOCKER_PGID
Write-Host $Environment.TRUENAS
Write-Host $Environment.REALM
Write-Host $Environment.PUID
Write-Host Funciono?


Write-Host "Finishing '$PSCommandPath'."
