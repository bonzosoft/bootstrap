function Set-DockerSecret {
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName="Value")]
    [OutputType([void])]
    [OutputType([IO.FileInfo])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]$Path = $Script:Context.SecretsDir,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(ParameterSetName="Value", Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(ParameterSetName="Password", Mandatory)]
        [switch]$Password,

        [Parameter(ParameterSetName="JwtSecret", Mandatory)]
        [switch]$JwtSecret,

        [Parameter(ParameterSetName="Base64", Mandatory)]
        [switch]$Base64,

        [Parameter(ParameterSetName="Password")]
        [Parameter(ParameterSetName="JwtSecret")]
        [Parameter(ParameterSetName="Base64")]
        [ValidateRange(1,128)]
        [int]$Length = 32,

        [Parameter()]
        [switch]$Overwrite,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [byte[]]$bytes = @()
        [IO.FileInfo]$secretFile = Join-Path -Path $Path.FullName -ChildPath $Name
        [IO.FileInfo]$temporaryFile = $null
        [string]$currentValue = ""
        [IO.UnixFileMode]$filePermission = [IO.UnixFileMode]::UserRead + [IO.UnixFileMode]::UserWrite

    }

    end {
        switch ($PSCmdlet.ParameterSetName) {
            "Value" {
                $currentValue = $Value
            }
            "Password" {
                $bytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
                $currentValue = [Convert]::ToBase64String($bytes)
                $currentValue = $currentValue.TrimEnd('=').Replace('+','-').Replace('/','_')
            }
            "JwtSecret" {
                $bytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
                $currentValue = [System.Buffers.Text.Base64Url]::EncodeToString($bytes)
            }
            "Base64" {
                $bytes = [Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
                $currentValue = [Convert]::ToBase64String($bytes)
                $currentValue = "base64:" + $currentValue
            }
            default {
                throw "Unknown ParameterSetName '$($PSCmdlet.ParameterSetName)'."
            }
        }
        
        if (-not (Test-Path -Path $secretFile.FullName) -or $Overwrite.IsPresent) {
            $temporaryFile = New-TemporaryFile
            if ($IsLinux) {
                [IO.File]::SetUnixFileMode($temporaryFile.FullName, $filePermission)
            }

            New-Item -Path $secretFile.Directory -ItemType Directory -Force | Out-Null
            if ($secretFile.Linktarget) {
                Move-Item -Path $temporaryFile.FullName -Destination $secretFile.LinkTarget -Force
            }
            else {
                Move-Item -Path $temporaryFile.FullName -Destination $secretFile.FullName -Force
            }

            if ($IsLinux) {
                [IO.File]::SetUnixFileMode($secretFile.FullName, $filePermission)
            }
        }
        else {
            if ($IsLinux) {
                [IO.File]::SetUnixFileMode($secretFile.FullName, $filePermission)
            }
        }

        if ($PassThru.IsPresent) {
            Write-Output -InputObject $secretFile
        }
    }
}
