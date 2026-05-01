function Import-DockerVariables {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $Script:Context.DotEnvFile
    )

    end {
        Get-Content $Path | ForEach-Object {
            if ($PSItem -match '^\s*$' -or $PSItem -match '^\s*#') {
                return
            }
            $key, $value = $PSItem -split '=', 2
            Set-Variable -Name $key.Trim() -Value $value.Trim('"') -Scope Script
            #$Env:$key = $value.Trim('"')
        }
    }
}