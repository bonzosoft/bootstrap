#!/usr/bin/env pwsh


Write-Host "Loading '$PSCommandPath'."


### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON_POSTDEPLOY" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON_POSTDEPLOY" -Scope Global -Value $true
}


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


################################################################################
### Script #####################################################################

# nop


Write-Host "Finishing '$PSCommandPath'."