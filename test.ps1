#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    Write-Host "hola mundo v2"
}

process {
    Write-Host "pasa"
}

end {
    Write-Host "adios mundo"
}

