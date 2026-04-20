## SINGLETON ###################################################################
if (Get-Variable -Name _COMMON_SOURCED -Scope Script -ErrorAction SilentlyContinue) {
    Write-Host "Trying to reload $PSCommandPath. Skipping."
    return
} else {
    Write-Host "Loading $PSCommandPath"
    Set-Variable -Name _COMMON_SOURCED -Value $true -Scope Script -Option ReadOnly
}


## CONFIGURATION ###############################################################
Set-StrictMode -Version Latest


## MODULES #####################################################################
#Import-Module -Name /PSModules/pwsh-dotenv
Import-Module -Name /PSModules/powershell-yaml


## VARIABLES ###################################################################
[IO.DirectoryInfo]$Script:WORKINGDIR = $Script:ENTRYSCRIPT.Directory # $(Get-Location).Path
[IO.DirectoryInfo]$Script:COMMONDIR  = $PSScriptRoot
[IO.DirectoryInfo]$Script:CONFIGDIR  = Join-Path -Path $Script:WORKINGDIR -ChildPath "./config"
[IO.DirectoryInfo]$Script:IncludeDir = Join-Path -Path $Script:WORKINGDIR -ChildPath "./include"
[IO.DirectoryInfo]$Script:SecretsDir = Join-Path -Path $Script:WORKINGDIR -ChildPath "./.secrets"
[IO.DirectoryInfo]$Script:DataDir    = Join-Path -Path $Script:WORKINGDIR -ChildPath "./state"
[IO.FileInfo]$Script:workingDotEnvFile  = Join-Path -Path $Script:WORKINGDIR -ChildPath "./.env"
[IO.FileInfo]$Script:workingComposeFile = Join-Path -Path $Script:WORKINGDIR -ChildPath "./compose.yaml"
[IO.FileInfo]$Script:commonDotEnvFile   = Join-Path -Path $Script:COMMONDIR -ChildPath "./.env.common"
[IO.FileInfo]$nextScript                = Join-Path -Path $Script:COMMONDIR -ChildPath "common.$($($Script:ENTRYSCRIPT).Name)"


## FUNCTIONS ###################################################################
function Write-Log {
    [CmdletBinding(PositionalBinding=$true)]
    [OutputType([void])]

    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERRO", "SUCC")]
        [string]$Level,

        [Parameter()]
        [ValidateNotNull()]
        [string]$Message
    )

    [string]$displayeMessage = ""
    [string]$timestamp = $(Get-Date -Format "yyyy-MM-dd\THH:mm:ss.fffK")
    [string]$separator = "  "
    [int[]]$position = @()
    [hashtable]$COLOR = @{
        RED     = "`e[31m"
        GREEN   = "`e[32m"
        YELLOW  = "`e[33m"
        BLUE    = "`e[34m"
        MAGENTA = "`e[35m"
        CYAN    = "`e[36m"
        RESET   = "`e[0m"
    }

    if ($Message) {
        $displayeMessage = $timestamp
        switch ($Level) {
            "INFO" {
                $displayeMessage += $separator + "[" + $COLOR.CYAN + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
            "WARN" {
                $displayeMessage += $separator + "[" + $COLOR.YELLOW + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
            "ERRO" {
                $displayeMessage += $separator + "[" + $COLOR.RED + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
            "SUCC" {
                $displayeMessage += $separator + "[" + $COLOR.GREEN + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
        }
        $displayeMessage += $Message
    }
    else {
        try {
            $position = $Host.UI.RawUI.CursorPosition
            $position.X = ($timestamp.Length + 3)
            $position.Y = ($position.Y - 1)
            $Host.UI.RawUI.CursorPosition = $position
        }
        catch {
            throw "Unable to configurate screen position."
        }

        switch ($Level) {
            "SUCC" {
                $displayeMessage = $COLOR.GREEN + " OK " + $COLOR.RESET
            }
            "ERRO" {
                $displayeMessage = $COLOR.RED + "FAIL" + $COLOR.RESET
            }
            default {
                throw "Parameter 'Message' is mandatory for option level '$Level'."
            }
        }
    }
    Write-Information $displayeMessage -InformationAction Continue
}

function Set-DockerVariable {
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Value,

        [Parameter()]
        [switch]$Force, #encuentra archivos que normalmente no (ocultos)

        [Parameter()]
        [switch]$Overwrite, #sobrescribe el valor si existe

        [Parameter()]
        [switch]$Append #añade el valor si no existe
    )

    # constants
    [string]$delimiter = " = "

    # variables
    [System.IO.FileInfo]$workingPath = $null
    [System.IO.FileInfo]$temporaryFile = $null
    [System.Collections.Generic.List[string]]$inputLines = @()
    [System.Collections.Generic.List[string]]$outputLines = @()
    [string]$currentName = ""
    [string]$currentValue = ""
    [string]$currentComment = ""
    [string]$currentLeftover = ""
    [bool]$keyFound = $false
    [hashtable]$matches = @{}

    if (Test-Path -Path $Path) {
        $workingPath = Get-Item -Path $Path -Force
    }
    else {
        $workingPath = New-Item -Path $Path -ItemType File
    }

    $inputLines = Get-Content $workingPath.FullName -Encoding UTF8

    foreach ($line in $inputLines) {
        $currentName = ""
        $currentValue = ""
        $currentComment = ""
        $currentLeftover = ""

        if (($line -match '^\s*#') -or ($line -match '^\s*$')) { # comment line starting with # or empty
            $outputLines.Add($line)
            continue
        }

        if ($line -match '^\s*(?<name>.*?)\s*(?<delimiter>[=:])\s*(?<leftover>.*)$') {
            # ^                 beginning of line
            # \s*               zero or more whitespace characters
            # (?<name>.*?)      capturing group 'name' of zero or more characters (lazy match, captures as few characters as possible)
            # \s*               zero or more whitespace characters
            # ([=:])            capturing group of = or :
            # \s*               zero or more whitespace characters
            # (?<leftover>.*)   capturing group 'leftover' of zero or more characters (greedy, captures as many characters as possible)
            # $                 end of line

            if ($matches.ContainsKey("name")) {
                $currentName = $matches.name #$matches[1]
            }
            if ($matches.ContainsKey("leftover")) {
                $currentLeftover = $matches.leftover #$matches[3]
            }

            switch -Regex ($currentLeftover) {
                '^[""''](?<value>[^""'']*)[""''](?:\s+(#)\s*(?<comment>.*))?$' {
                    ## quoted text
                    # ^                     beginning of line
                    # [""'']                " or '
                    # (?<value>[^""'']*)   capturing group 'value' zero or more characters different of " or '
                    # [""'']                " or '
                    # (?:...)?              non-capturing group, one or zero instances
                    # \s+                   one or more whitespace characters
                    # (#)                   capturing group of character #
                    # \s*                   zero or more whitespace characters
                    # (?<comment>.*)        capturing group of zero or more characters (greedy, captures as many characters as possible)
                    # $                     end of line

                    if ($matches.ContainsKey("value")) {
                        $currentValue = $matches.value
                    }
                    if ($matches.ContainsKey("comment")) {
                        $currentComment = $matches.comment
                    }
                    
                }
                '^(?<value>.*?)(?:\s+(#)\s*(?<comment>.*))?$' {
                    ## non-quoted text
                    # ^                 beginning of line
                    # (?<value>.*?)     capturing group 'value' of zero or more characters (lazy match, captures as few characters as possible)
                    # (?:...)?          non-capturing group, one or zero instances
                    # \s+               one or more whitespace characters
                    # (#)               capturing groupo of character #
                    # \s*               zero or more whitespace characters
                    # (?<comment>.*)    capturing group 'comment' of zero or more characters (greedy, captures as many characters as possible)
                    # $                 end of line

                    if ($matches.ContainsKey("value")) {
                        $currentValue = $matches.value
                    }
                    if ($matches.ContainsKey("comment")) {
                        $currentComment = $matches.comment
                    }
                }
                default {
                    throw "Invalid format: '$line'"
                }
            }
        }
        else {
            throw "Invalid format: '$line'."
        }

        if ($currentName -eq $Name) {
            $keyFound = $true

            if ($Overwrite.IsPresent) {
                # update new value
                $newLine = $currentName + $delimiter + $Value
            }
            else {
                # keep current value
                $newLine = $currentName + $delimiter + $currentValue
            }
        }
        else {
            # keep not-matching value
            $newLine = $currentName + $delimiter + $currentValue
        }

        if (-not [string]::IsNullOrWhiteSpace($currentComment)) {
            $newLine += " #" + $currentComment
        }

        $outputLines.Add($newLine)
    }

    if (-not $keyFound -and $Add.IsPresent) {
        $newLine = $Name + $delimiter + $Value 
        $outputLines.Add($newLine)
    }
   
    $temporaryFile = New-TemporaryFile
    Set-Content -Path $temporaryFile.FullName -Value $outputLines -Encoding UTF8
    if ($workingPath.Linktarget) {
        Move-Item -Path $temporaryFile.FullName -Destination $workingPath.LinkTarget -Force:$Force
    }
    else {
        Move-Item -Path $temporaryFile.FullName -Destination $workingPath.FullName -Force:$Force
    }
}

function Set-DockerSecret {
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName="Value")]
    [OutputType([void])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(ParameterSetName="Value", Mandatory)]
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
        [ValidateRange(1,1024)]
        [int]$Length = 32,

        [Parameter()]
        [switch]$Force
    )

    # constants

    # variables
    [byte[]]$bytes = @()
    [System.IO.DirectoryInfo]$workingPath = $null
    [System.IO.FileInfo]$secretFile = $null
    [System.IO.FileInfo]$temporaryFile = $null
    [string]$currentValue = ""

    if (Test-Path -Path $Path) {
        $workingPath = Get-Item -Path $Path -Force
    }
    else {
        $workingPath = New-Item -Path $Path -ItemType Directory
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        "Value" {
            $currentValue = $Value
        }
        "Password" {
            $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
            $currentValue = [Convert]::ToBase64String($bytes)
            $currentValue = $currentValue.TrimEnd('=').Replace('+','-').Replace('/','_')
        }
        "JwtSecret" {
            $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
            $currentValue = [System.Buffers.Text.Base64Url]::EncodeToString($bytes)
        }
        "Base64" {
            $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
            $currentValue = [Convert]::ToBase64String($bytes)
            $currentValue = "base64:" + $currentValue
        }
        default {
            throw "Unknown ParameterSetName '$($PSCmdlet.ParameterSetName)'."
        }
    }
    
    $secretFile = Join-Path -Path $Path.FullName -ChildPath $Name
    if (-not (Test-Path -Path $secretFile.FullName) -or $Force.IsPresent) {
        $temporaryFile = New-TemporaryFile
        if ($IsLinux) {
            chmod 600 $temporaryFile.FullName
        }
        Set-Content -Path $temporaryFile.FullName -Value $currentValue -Encoding UTF8 -NoNewLine
        if ($secretFile.Linktarget) {
            Move-Item -Path $temporaryFile.FullName -Destination $secretFile.LinkTarget -Force
        }
        else {
            Move-Item -Path $temporaryFile.FullName -Destination $secretFile.FullName -Force
        }
        if ($IsLinux) {
            chmod 600 $temporaryFile.FullName
        }
    }
    else {
        if ($IsLinux) {
            chmod 600 $secretFile.FullName
        }
    }
}

function Grant-DockerPermission {
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateRange(0,65535)]
        [int]$PUID,

        [Parameter(Mandatory)]
        [ValidateRange(0,65535)]
        [int]$PGID,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-7]{3,4}$')] # Ensures valid octal format (e.g., '755' or '0644')
        [string]$Mode,

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [switch]$Force
    )

    # constants

    # variables
    [System.IO.FileSystemInfo]$workingPath = $null
    [System.IO.FileSystemInfo[]]$items = @()
    [System.Collections.Generic.List[System.IO.DirectoryInfo]]$directories = @()
    [System.Collections.Generic.List[System.IO.FileInfo]]$files = @()
    [string]$directoryMode = ""
    [string]$fileMode = ""
    [int]$digit = 0

    if (Test-Path -Path $Path) {
        if ((Get-Item $Path).IsPSContainer) {
            [System.IO.DirectoryInfo]$workingPath = Get-Item -Path $Path
        }
        else {
            [System.IO.FileInfo]$workingPath = Get-Item -Path $Path
        }
    }
    else {
        [System.IO.DirectoryInfo]$workingPath = New-Item -Path $Path -ItemType Directory
    }

    $directoryMode = $Mode
    $fileMode = -join ($Mode.ToCharArray() | ForEach-Object {
        $digit = [int]$PSItem
        if ($digit % 2) {
            $digit-1
        }
        else {
            $digit
        }
    })

    $items = Get-Item -Path $workingPath.FullName -Force:$Force
    if (($workingPath.PSIsContainer) -and $Recurse.IsPresent) {
        $items += Get-ChildItem -Path $workingPath.FullName -Force:$Force -Recurse
    }

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            $directories.Add($item)
        }
        else {
            $files.Add($item)
        }
    }

    if ($IsLinux) {
        chown "${PUID}:${PGID}" $items.FullName
        if ($directories) {
            #chmod $directoryMode $directories.FullName
            $directories.FullName | xargs -r chmod $directoryMode
        }
        if ($files) {
            #chmod $fileMode $Files.FullName
            $files.FullName | xargs -r chmod $fileMode
        }
    }
}

function Get-DockerCompose {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Path
    )

    [IO.FileInfo]$workingPath = $null
    [string[]]$content = @()
    [hashtable]$compose = @{}

    if (Test-Path -Path $Path) {
        $workingPath = Get-Item -Path $Path -Force
    }
    else {
        throw "File not found."
    }

    try {
        $content = docker compose -f $workingPath.FullName config
        #--no-consistency		Don't check model consistency - warning: may produce invalid Compose output
        #--no-env-resolution	Don't resolve service env files
        #--no-interpolate		Don't interpolate environment variables
        #--no-normalize		    Don't normalize compose model (convierte formatos cortos a largos)
        #--no-path-resolution	Don't resolve file paths

        if ($LASTEXITCODE) {
            throw "Unable to generate compose file: $($Error[0])"
        }
        $compose = $content | ConvertFrom-Yaml
    }
    catch {
        throw $PSItem.Exception.Message
    }
    
    return $compose
}

function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([string[]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Compose
    )
    [string[]]$volumes = @()

    foreach ($serviceName in $Compose.services.Keys) {
        $service = $Compose.services[$serviceName]
        Write-Host "service:"
        $service | Format-List *
        if ($service.volumes) {
            foreach ($volume in $service.volumes) {
                if ($volume.type -eq "bind") {
                    $volumes += $volume.source        
                }
            }
        }
    }

    return $volumes
}

function Get-DockerUser {
    (get-content /host/etc/group | ForEach-Object {if ($PSItem -match "^docker.*$"){$PSItem}}).Count
}

function Test-DockerSubmodule {
    [CmdletBinding()]
    [OutputType([bool])]

    param (

    )

    [string]$matchString = $Script:IncludeDir.Basename
    
    if ($PSCommandPath -like "*$matchString*" ) {
        return $true
    }
    else {
        return $false
    }
}

function Test-Truenas {
    [CmdletBinding(DefaultParameterSetName="Exists")]
    [OuptutType([bool], "Exists")]
    [OuptutType([version], "Version")]

    param(
        [Parameter(ParameterSetName="Version")]
        [switch]$Version
    )
    [IO.FileInfo]$versionFile = "/etc/version"
    if ($versionFile.Exists) {
        if ($Version.IsPresent) {
            return [version](Get-Content -Path $versionFile.FullName)
        }
        else {
            return $true
        }
    }
    else {
        if ($Version.IsPresent) {
            return [version]$null
        }
        else{
            return $false
        }
    }
}

## LOAD NEXT SCRIPT BLOCK ######################################################
. $nextScript
Write-Host "Finishing $PSCommandPath"