function New-DockerPasswordHash {
    [CmdletBinding(DefaultParameterSetName = "Base64")]
    [OutputType([securestring])]

    param (
        [Parameter()]
        [securestring]$Password = $null,

        [Parameter(Mandatory, ParameterSetName = "Base64")]
        [switch]$Base64,

        [Parameter(Mandatory, ParameterSetName = "Base64Url")]
        [switch]$Base64Url,

        [Parameter(Mandatory, ParameterSetName = "Jwt")]
        [switch]$Jwt,

        [Parameter(Mandatory, ParameterSetName = "Argon2")]
        [switch]$Argon2,

        [Parameter(Mandatory, ParameterSetName = "BCrypt")]
        [switch]$BCrypt,

        [Parameter()]
        [int]$Length = 32
    )

    begin {
        [byte[]]$seed = @()
        #[securestring]$hashedString = $null
    }

    process {
        if ($null -eq $Password) {
            $seed = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
            $tmp = [System.Buffers.Text.Base64Url]::EncodeToString($seed)
        }
        else {
            $tmp = ConvertFrom-SecureString -SecureString $Password -AsPlainText
        }

        Write-Host $tmp

        switch ($PSCmdlet.ParameterSetName) {
            "Base64" {
                $hashedString = [System.Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes( $tmp ))
            }
            "Base64Url" {
                $hashedString = [System.Buffers.Text.Base64Url]::EncodeToString([Text.Encoding]::UTF8.GetBytes( $tmp ))
            }
            "Jwt" {
                $hashedString = [System.Buffers.Text.Base64Url]::EncodeToString([Text.Encoding]::UTF8.GetBytes( $tmp ))
            }
            "Argon2" {
                if (-not (Get-Command -Name "argon2" -ErrorAction SilentlyContinue)) {
                    throw "Command 'argon2' not found. Please install 'argon2' package."
                }
                $hashedString = $tmp | argon2 $seed -id -t 3 -k 65536 -p 1 -l $Length -e
            }
            "BCrypt" {
                if (-not (Get-Command -Name "mkpasswd" -ErrorAction SilentlyContinue)) {
                    throw "Command 'mkpasswd' not found. Please install 'whois' package."
                }
                $hashedString = $tmp | mkpasswd --method=bcrypt --rounds=10
            }
            default {
                throw "Unknonw encryption type."
            }
        }
        Write-Host $hashedString
        Write-Output -InputObject (ConvertTo-SecureString -String $hashedString -AsPlainText)
    }

    end {
    
    }
}