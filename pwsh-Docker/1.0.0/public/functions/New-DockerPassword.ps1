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
    }

    process {
        if ($null -eq $Password) {
            #$plainString = New-Guid

            [byte[]]$bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
            $plainString = [System.Convert]::ToBase64String($bytes)           
        }
        else {
            $plainString = ConvertFrom-SecureString -SecureString $Password -AsPlainText
        }
        $seed = [System.Text.Encoding]::UTF8.GetBytes($plainString)

        Write-Warning $PSCmdlet.ParameterSetName
        Write-Warning $plainString

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
                
                # generating salt
                #$chars = "0123456789ABCDEF"
                #[string]$salt = -join ((1..16) | ForEach-Object { 
                #    $chars[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $chars.Length)] 
                #})
                ## converting salt to hex bytes
                #[bytes[]]$salt = $salt -replace '(..)', '\x$1'
                [byte[]]$salt = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16)
                [string]$hexSalt = $salt -join '' -replace '(..)', '\x$1'               
                $hashedString = /bin/bash -c "echo -n '$plainString' | argon2 `$(printf $hexSalt) -id -t 3 -k 65536 -p 1 -e"

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
        Write-Warning "pasa4"
        Write-Warning $hashedString
        Write-Warning "fin"
        Write-Output -InputObject $hashedString
    }

    end {
    
    }
}