
#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    $MyInvocation  | Format-List *

    Write-Host "PsCommandPath"
    $PSCommandPath

    Write-Host "Psscriptr<oot"
    $PSScriptRoot

    Write-Host "fileinof"
    [IO.FIleInfo]$currentScriptFile = $PSCommandPath
    $currentScriptFile | Format-List *


    function Test{
        $MyInvocation  | Format-List *

    }

    Test
}