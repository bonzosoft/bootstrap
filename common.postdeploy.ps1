#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param(
    
)

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    [IO.FileInfo]$currentScriptFile = $PSCommandPath
    New-Variable -Name "singleton" -Scope Global -Value ("__INCLUDED_$($currentScriptFile.Name.Replace(".","_").ToUpper())__")
    if (Get-Variable -Name $singleton -Scope Global -ErrorAction SilentlyContinue) {
        Write-Information -MessageData "Script '$($currentScriptFile.FullName)' already loaded. Skipping."
        return
    }
    else {
        Write-Information -MessageData "Loading script '$($currentScriptFile.FullName)'."
        New-Variable -Name $singleton -Scope Global -Value $true
    }
    Remove-Variable -Name $singleton
}

process {
    # ==========================================================================
    # LOAD COMMON ASSETS
    # ==========================================================================
    . (Join-Path -Path $currentScriptFile.DirectoryName -ChildPath @("common.ps1"))
}

end {
    Write-Information -MessageData "Loaded script '$($currentScriptFile.FullName)'."
}
