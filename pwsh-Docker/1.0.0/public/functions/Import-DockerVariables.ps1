function Import-DockerVariables {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $Script:Context.DotEnvFile,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$Context = $Script:Context
    )

    end {
        Get-Content $Path | ForEach-Object {
            if ($PSItem -match '^\s*$' -or $PSItem -match '^\s*#') {
                return
            }
            $key, $value = $PSItem -split '=', 2
            Write-host "Set-Variable -Name $key"
            #Set-Variable -Name $key.Trim() -Value $value.Trim('"') -Scope Script
            #$Env:$key = $value.Trim('"')
            $Script:Context | Add-Member -MemberType NoteProperty -Name $key.Trim() -Value $value.Trim('"') -Force
        }
    }
}