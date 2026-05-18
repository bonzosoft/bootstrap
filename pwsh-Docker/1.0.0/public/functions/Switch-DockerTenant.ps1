function Switch-DockerTenant {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [switch]$PassThru
    )
    
    begin {
        [IO.FileInfo]$source = Join-Path -Path $Script:Context.DotEnvFile.Directory -ChildPath "$($Script:Context.DotEnvFile.Name).$($Script:Context.Tenant)"
        [IO.FileInfo]$target = $Script:Context.DotEnvFile
    }

    end {
        if (Test-Path -Path $source) {
            New-Item -Path $target -Value $source -ItemType SymbolicLink -Force | Out-Null
        }
        else {
            throw "Source '.env' file not found."
        }
    
        if ($PassThru.IsPresent) {
            Write-Output -InputObject $target
        }
    }
}