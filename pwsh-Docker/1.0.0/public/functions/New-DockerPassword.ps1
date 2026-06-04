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
                $hashedString = [Convert]::ToBase64String($seed)
            }
            "Argon2" {
                if (-not (Get-Command -Name "argon2" -ErrorAction SilentlyContinue)) {
                    throw "Command 'argon2' not found. Please install 'argon2' package."
                }
                #$salt = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
                #$hexString = [System.Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
                #Write-Information "salt: $hexStringt"
                #$caracteres = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                $chars = "0123456789ABCDEF"
                $salt = -join ((1..16) | ForEach-Object { 
                    $chars[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $chars.Length)] 
                })

                #$salt = "aaaaaaaaaaaaaaaa"
                #$password = "tu_contraseña_aqui" # Reemplaza por la misma contraseña que usaste en it-tools
                
                # 2. Convertimos "aaaaaaaaaaaaaaaa" a un formato de escape: "\xaa\xaa\xaa\xaa\xaa\xaa\xaa\xaa"
                # Bash interpreta esto a nivel de bytes sin corromper nada.
                Write-Warning $salt
                $salt = $salt -replace '(..)', '\x$1'
                Write-Warning $salt
                Write-Warning $seed
                
                # 3. Construimos el comando completo.
                # Usamos $(printf ...) para que bash genere los bytes en bruto en ese mismo instante.
                # (El parámetro -e le dice a argon2 que devuelva el string final $argon2id$...)
                
                $hashedString = /bin/bash -c "echo -n '$seed' | argon2 `$(printf '$salt') -id -t 3 -k 65536 -p 1 -e"
                Write-Warning $hashedString

                #$hashedString = [System.Text.Encoding]::UTF8.GetString($seed) | argon2 $salt -id -t 3 -k 65536 -p 1 -l $Length -e


                ### powershell
                ## argon 2
                #Add-Type -Path "./Konscious.Security.Cryptography.Argon2.dll"
                #
                #$password = "changeme"
                #
                ## salt aleatorio
                #$salt = New-Object byte[] 16
                #[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
                #
                ## convertir password
                #$passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($password)
                #
                ## crear Argon2id
                #$argon2 = New-Object Konscious.Security.Cryptography.Argon2id($passwordBytes)
                #
                #$argon2.Salt = $salt
                #$argon2.Iterations = 4
                #$argon2.MemorySize = 65536   # 64 MB
                #$argon2.DegreeOfParallelism = 2
                #
                ## hash
                #$hash = $argon2.GetBytes(32)
                #
                ## base64 para guardar
                #$hashB64 = [Convert]::ToBase64String($hash)
                #$saltB64 = [Convert]::ToBase64String($salt)
                #
                #$hashB64
                #$saltB64




                #if ($LASTEXITCODE) {
                #    throw "A problem was found hashing the password."
                #}
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