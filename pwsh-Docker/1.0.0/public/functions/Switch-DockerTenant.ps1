function Switch-DockerTenant {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [switch]$PassThru
    )
    
    begin {
        [IO.FileInfo]$source = Join-Path -Path $Script:Context.Path.DotEnvFile.Directory -ChildPath "$($Script:Context.Path.DotEnvFile.Name).$($Script:Context.Tenant)"
        [IO.FileInfo]$target = $Script:Context.Path.DotEnvFile
    }

    end {
        if (Test-Path -Path $source) {
            #New-Item -Path $target -Value $source -ItemType SymbolicLink -Force | Out-Null
            Copy-Item -Path $source -Destination $target -Force | Out-Null
        }
        else {
            throw "Source '.env' file not found."
        }
    
        if ($PassThru.IsPresent) {
            Write-Output -InputObject $target
        }
    }
}