#!/usr/bin/env pwsh


### SINGLETON ##################################################################
if (Get-Variable -Name "__INCLUDED_COMMON_ONCLONE" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_COMMON_ONCLONE" -Scope Global -Value $true
}


Write-Information -Message "Loading '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


Write-Information -Message "Finishing '$PSCommandPath'."
