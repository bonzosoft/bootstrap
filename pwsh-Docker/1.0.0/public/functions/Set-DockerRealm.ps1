function Set-DockerRealm {
    [CmdletBinding()]
    [OutputType([void])]

    param()
    
    [IO.FileInfo]$source = Join-Path -Path $Script:Context.DotEnvFile.Directory -ChildPath "$($Script:Context.DotEnvFile.Name).$($Script:Context.HostInfo.REALM)"
    [IO.FileInfo]$target = $Context.DotEnvFile

    Write-Host "source: $source"
    Write-Host "target: $target"
    
    if (Test-Path -Path $source) {
        New-Item -Path $target -ItemType SymbolicLink -Value $source -Force | Out-Null
    }
}