function New-DockerPassword {
    [CmdletBinding(DefaultParameterSetName = "Plain")]
    [OutputType([securestring])]

    param (
        [Parameter()]
        [SecureString]$Password = $null,

        [Parameter(Mandatory, ParameterSetName = "Plain")]
        [switch]$AsPlainText,

        [Parameter(Mandatory, ParameterSetName = "Base64")]
        [switch]$AsBase64,

        [Parameter(Mandatory, ParameterSetName = "Base64Url")]
        [switch]$AsBase64Url,

        [Parameter(Mandatory, ParameterSetName = "Jwt")]
        [switch]$AsJwtSecret,

        [Parameter(Mandatory, ParameterSetName = "Argon2")]
        [switch]$AsArgon2,

        [Parameter(Mandatory, ParameterSetName = "BCrypt")]
        [switch]$AsBCrypt,

        [Parameter()]
        [int]$Length = 32
    )

    begin {
        [byte[]]$seed = @()
        [string]$plainString = $null
        [string]$hashedString = $null
        [string]$validChars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-~"
    }

    process {
        if ($null -eq $Password) {
            $plainString = -join ((1..32) | ForEach-Object { 
                $validChars[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $validChars.Length)] 
            })        
        }
        else {
            $plainString = ConvertFrom-SecureString -SecureString $Password -AsPlainText
        }
        $seed = [System.Text.Encoding]::UTF8.GetBytes($plainString)

        switch ($PSCmdlet.ParameterSetName) {
            "Plain" {
                $hashedString = $plainString
            }
            ( {($PSItem -eq "Base64") -or ($PSItem -eq "Jwt")} ) {
                $hashedString = [Convert]::ToBase64String($seed)
            }
            "Base64Url" {
                $hashedString = [Convert]::ToBase64String($seed).TrimEnd('=').Replace('+','-').Replace('/','_')
            }
            "Argon2" {
                if (-not (Get-Command -Name "argon2" -ErrorAction SilentlyContinue)) {
                    throw "Command 'argon2' not found. Please install 'argon2' package."
                }
                [byte[]]$saltBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
                $hexSalt = ($saltBytes | ForEach-Object { '\x' + $PSItem.ToString('x2') }) -join ''
                $hashedString = /bin/bash -c "echo -n '$plainString' | argon2 `$(printf $hexSalt) -id -t 3 -k 65536 -p 1 -e"

                #$salt = [System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
                #$salt = openssl rand -base64 32
                #$plainString | argon2 $salt -id -t 3 -k 65536 -p 1 -e

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
                throw "Unknown encryption type."
            }
        }
    }

    end {
        Write-Output -InputObject $hashedString
    }
}