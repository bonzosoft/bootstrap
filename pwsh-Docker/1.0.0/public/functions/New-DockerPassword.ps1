function New-DockerPassword {
    [CmdletBinding(DefaultParameterSetName = "Plain")]
    [OutputType([securestring])]

    param (
        [Parameter()]
        [securestring]$Password = $null,

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
            ("Base64" -or "Jwt") {
                $hashedString = [Convert]::ToBase64String($seed)
            }
            "Base64Url" {
                #$hashedString = [System.Buffers.Text.Base64Url]::EncodeToString([Text.Encoding]::UTF8.GetBytes($seed))
                $hashedString = [Convert]::ToBase64String($seed).TrimEnd('=').Replace('+','-').Replace('/','_')
            }
            "Argon2" {
                if (-not (Get-Command -Name "argon2" -ErrorAction SilentlyContinue)) {
                    throw "Command 'argon2' not found. Please install 'argon2' package."
                }
                $chars = "0123456789ABCDEF"
                # generating salt
                $salt = -join ((1..16) | ForEach-Object { 
                    $chars[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $chars.Length)] 
                })
                # converting salt to hex
                $salt = $salt -replace '(..)', '\x$1'
                
                $hashedString = /bin/bash -c "echo -n '$(ConvertFrom-SecureString -SecureString $Password -AsPlainText)' | argon2 `$(printf '$seed') -id -t 3 -k 65536 -p 1 -e"

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