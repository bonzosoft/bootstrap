function Import-DockerVariables {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $Script:Context.MainDotEnvFile,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$Context = $Script:Context,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [PSCustomObject]$object = [PSCustomObject]@{}
    }
    end {
        Get-Content $Path | ForEach-Object {
            if ($PSItem -match '^\s*$' -or $PSItem -match '^\s*#') {
                return
            }
            $key, $value = $PSItem -split '=', 2
            $object | Add-Member -MemberType NoteProperty -Name $key.Trim() -Value $value.Trim('"') -Force
        }

        $Context | Add-Member -MemberType NoteProperty -Name "Environment" -Value $object -Force

        if ($PassThru.IsPresent) {
            Write-Output -InputObject $Context
        }
    }
}