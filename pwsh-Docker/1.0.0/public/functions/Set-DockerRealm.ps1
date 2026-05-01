function Set-DockerRealm {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [switch]$PassThru
    )
    
    begin {
        [IO.FileInfo]$source = Join-Path -Path $Script:Context.DotEnvFile.Directory -ChildPath "$($Script:Context.DotEnvFile.Name).$($Script:Context.HostInfo.REALM)"
        [IO.FileInfo]$target = $Context.DotEnvFile
    }

    end {
        if (Test-Path -Path $source) {
            New-Item -Path $target -ItemType SymbolicLink -Value $source -Force | Out-Null
        }
    
        if ($PassThru.IsPresent) {
            return $target
        }
    }
}