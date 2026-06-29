#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param(
    
)

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    New-Variable -Name "singleton" -Scope Global -Value ("__INCLUDED_$(([IO.FileInfo]$PSCommandPath).Name.Replace(".","_").ToUpper())__")
    if (Get-Variable -Name $singleton -Scope Global -ErrorAction SilentlyContinue) {
        Write-Information -MessageData "Script '$PSCommandPath' already loaded. Skipping."
        return
    }
    else {
        Write-Information -MessageData "Loading script '$PSCommandPath'."
        New-Variable -Name $singleton -Scope Global -Value $true
    }
    Remove-Variable -Name $singleton
}

process {
    # ==========================================================================
    # LOAD COMMON ASSETS
    # ==========================================================================
    . (Join-Path -Path ([IO.FileInfo]$PSCommandPath).Directory -ChildPath @("common.ps1"))
}

end {
    Write-Information -MessageData "Completed script '$PSCommandPath'."
}
