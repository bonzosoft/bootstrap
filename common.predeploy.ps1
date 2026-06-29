#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param(
    
)

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    [IO.FileInfo]$currentScriptInfo = $PSCommandPath
    New-Variable -Name "singleton" -Scope Global -Value ("__INCLUDED_$($currentScriptInfo.Name.Replace(".","_").ToUpper())__")
    if (Get-Variable -Name $singleton -Scope Global -ErrorAction SilentlyContinue) {
        Write-Information -MessageData "Script '$($currentScriptInfo.FullName)' already loaded. Skipping."
        return
    }
    else {
        Write-Information -MessageData "Loading script '$($currentScriptInfo.FullName)'."
        New-Variable -Name $singleton -Scope Global -Value $true
    }
    Remove-Variable -Name $singleton


    # ==========================================================================
    # LOAD COMMON ASSETS
    # ==========================================================================
    . (Join-Path -Path $currentScriptInfo.DirectoryName -ChildPath @("common.ps1"))
}

process {

}

end {
    Write-Information -MessageData "Loaded script '$($currentScriptInfo.FullName)'."
}
