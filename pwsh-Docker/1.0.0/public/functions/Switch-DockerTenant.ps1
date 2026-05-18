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
            #New-Item -Path $target -Value $source -ItemType SymbolicLink -Force | Out-Null
            Copy-Item -Path $source -Destination $target -Force | Out-Null
        }
        else {
            Write-Error -Message "Source '.env' file not found for tenant '$($Script:Context.Tenant)'."
        }
    
        if ($PassThru.IsPresent) {
            Write-Output -InputObject $target
        }
    }
}