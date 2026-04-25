#!/usr/bin/env pwsh


Write-Host "Loading '$PSCommandPath.'"


### Configuration ##############################################################
Set-StrictMode -Version Latest


### Load module ################################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker") -ArgumentList $ENTRYSCRIPT


### Script #####################################################################
# nop


Write-Host "Finishing '$PSCommandPath'."
