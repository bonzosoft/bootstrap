function Set-DockerSecret {
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType([void])]
    [OutputType([IO.FileInfo])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]$Path = $Script:Context.SecretsDir,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [switch]$Overwrite,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [IO.FileInfo]$secretFile = Join-Path -Path $Path.FullName -ChildPath $Name
        [IO.FileInfo]$temporaryFile = $null
        [string]$currentValue = ""
    }

    end {        
        if (-not (Test-Path -Path $secretFile.FullName) -or $Overwrite.IsPresent) {
            $temporaryFile = New-TemporaryFile
            if ($IsLinux) {
                [IO.File]::SetUnixFileMode($temporaryFile.FullName, [IO.UnixFileMode]::UserWrite)
            }
            Set-Content -Path $temporaryFile.FullName -Value $currentValue -Encoding UTF8 -NoNewLine

            New-Item -Path $secretFile.Directory -ItemType Directory -Force | Out-Null
            if ($secretFile.Linktarget) {
                Move-Item -Path $temporaryFile.FullName -Destination $secretFile.LinkTarget -Force
            }
            else {
                Move-Item -Path $temporaryFile.FullName -Destination $secretFile.FullName -Force
            }
        }
        else {
            # nop
        }

        if ($PassThru.IsPresent) {
            Write-Output -InputObject $secretFile
        }
    }
}
