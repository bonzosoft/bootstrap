function New-DockerPassword {
    [CmdletBinding(DefaultParameterSetName = "Plain")]
    [OutputType([securestring])]

    param (
        [Parameter()]
        [securestring]$Password = $null,

        [Parameter(Mandatory, ParameterSetName = "Plain")]
        [switch]$Plain,

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
        }
        else {
            $seed = [System.Text.Encoding]::UTF8.GetBytes((ConvertFrom-SecureString -SecureString $Password -AsPlainText))
        }

        switch ($PSCmdlet.ParameterSetName) {
            "Plain" {
                $hashedString = $seed
            }
            "Base64" {
                $hashedString = [Convert]::ToBase64String($seed)
            }
            "Base64Url" {
                #$hashedString = [System.Buffers.Text.Base64Url]::EncodeToString([Text.Encoding]::UTF8.GetBytes($seed))
                $hashedString = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
            }
            "Jwt" {
                #$hashedString = [System.Buffers.Text.Base64Url]::EncodeToString([Text.Encoding]::UTF8.GetBytes($seed))
                $hashedString = [Convert]::ToBase64String($seed)
            }
            "Argon2" {
                if (-not (Get-Command -Name "argon2" -ErrorAction SilentlyContinue)) {
                    throw "Command 'argon2' not found. Please install 'argon2' package."
                }
                #$salt = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
                $salt = [System.Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
                $salt
                $hashedString = [System.Text.Encoding]::UTF8.GetString($seed) | argon2 $salt -id -t 3 -k 65536 -p 1 -l $Length -e
                if ($LASTEXITCODE) {
                    throw "A problem was found hashing the password."
                }
            }
            "BCrypt" {
                if (-not (Get-Command -Name "mkpasswd" -ErrorAction SilentlyContinue)) {
                    throw "Command 'mkpasswd' not found. Please install 'whois' package."
                }
                $hashedString = [System.Text.Encoding]::UTF8.GetString($seed) | mkpasswd --method=bcrypt --rounds=10
                if ($LASTEXITCODE) {
                    throw "A problem was found hashing the password."
                }
            }
            default {
                throw "Unknonw encryption type."
            }
        }
  
        Write-Output -InputObject (ConvertTo-SecureString -String $hashedString -AsPlainText)
    }

    end {
    
    }
}