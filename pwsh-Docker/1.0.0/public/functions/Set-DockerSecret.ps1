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

        #[System.IO.UnixFileMode]$fileMode =  ([System.IO.UnixFileMode]::UserRead -bor
        #                                      [System.IO.UnixFileMode]::UserWrite)
        [IO.UnixFileMode]$fileMode = [IO.UnixFileMode]::UserRead + [IO.UnixFileMode]::UserWrite
        Write-Host $fileMode
        <#
        None            0	    No permissions.
        
        OtherExecute    1	    Execute permission for others.
        OtherWrite  	2	    Write permission for others.
        OtherRead	    4	    Read permission for others.

        GroupExecute	8	    Execute permission for group.
        GroupWrite	    16	    Write permission for group.
        GroupRead	    32	    Read permission for group.

        UserExecute	    64	    Execute permission for owner.
        UserWrite	    128	    Write permission for owner.
        UserRead	    256	    Read permission for owner.

        StickyBit	    512	    Sticky bit permission.
        SetGroup	    1024    Set group permission.
        SetUser	        2048    Set user permission.
        #>
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
                #[IO.File]::SetUnixFileMode($temporaryFile.FullName, $fileMode)
                chmod 600 "$($temporaryFile.FullName)"
            }

            New-Item -Path $secretFile.Directory -ItemType Directory -Force | Out-Null
            if ($secretFile.Linktarget) {
                Move-Item -Path $temporaryFile.FullName -Destination $secretFile.LinkTarget -Force
            }
            else {
                Move-Item -Path $temporaryFile.FullName -Destination $secretFile.FullName -Force
            }
            if ($IsLinux) {
                #[IO.File]::SetUnixFileMode($secretFile.FullName, $fileMode)
                chmod 600 "$($secretFile.FullName)"
            }
        }
        else {
            if ($IsLinux) {
                #[IO.File]::SetUnixFileMode($secretFile.FullName, $fileMode)
                chmod 600 "$($secretFile.FullName)"
            }
        }

        if ($PassThru.IsPresent) {
            Write-Output -InputObject $secretFile
        }
    }
}
