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
        [object]$Value,

        [Parameter()]
        [switch]$Overwrite,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [IO.FileInfo]$secretFile = Join-Path -Path $Path.FullName -ChildPath $Name
        [IO.FileInfo]$temporaryFile = $null
    }

    end {        
        if (-not (Test-Path -Path $secretFile.FullName) -or $Overwrite.IsPresent) {
            $temporaryFile = New-TemporaryFile
            if ($IsLinux) {
                [IO.File]::SetUnixFileMode($temporaryFile.FullName, [IO.UnixFileMode]::UserWrite)
            }
            Write-Warning "value: $Value"
            if ($Value -is [SecureString]) {
                Set-Content -Path $temporaryFile.FullName -Value (ConvertFrom-SecureString -SecureString $Value -AsPlainText) -Encoding UTF8 -NoNewLine
            }
            else {
                Set-Content -Path $temporaryFile.FullName -Value $Value -Encoding UTF8 -NoNewLine
            }
            
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
