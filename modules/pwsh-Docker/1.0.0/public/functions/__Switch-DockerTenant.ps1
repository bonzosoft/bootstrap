function Switch-DockerTenant {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [switch]$PassThru
    )
    
    begin {
        [IO.FileInfo]$source = Join-Path -Path $Script:Context.MainDotEnvFile.Directory -ChildPath "$($Script:Context.MainDotEnvFile.Name).$($Script:Context.Tenant)"
        [IO.FileInfo]$target = $Script:Context.MainDotEnvFile
    }

    end {
        if (Test-Path -Path $source) {
            #New-Item -Path $target -Value $source -ItemType SymbolicLink -Force | Out-Null
            Copy-Item -Path $source -Destination $target -Force | Out-Null
        }
        else {
            Write-Warning -Message "Source '.env' file not found for tenant '$($Script:Context.Tenant)'."
        }
    
        if ($PassThru.IsPresent) {
            Write-Output -InputObject $target
        }
    }
}