[CmdletBinding()]
[OutputType([void])]

param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]$ENTRYSCRIPT 
)

Write-Host "Loading $PSCommandPath"

## CONFIGURATION ###############################################################
Set-StrictMode -Version Latest


## MODULES #####################################################################
Import-Module -Name /PSModules/powershell-yaml
#Import-Module -Name /PSModules/pwsh-dotenv


## VARIABLES ###################################################################
[IO.FileInfo]$Script:ENTRYSCRIPT = $ENTRYSCRIPT
[IO.DirectoryInfo]$Script:WORKINGDIR  = $Script:ENTRYSCRIPT.Directory
[IO.DirectoryInfo]$Script:INCLUDEDIR  = Join-Path -Path $Script:WORKINGDIR -ChildPath "include"
[IO.DirectoryInfo]$Script:CONFIGDIR   = Join-Path -Path $Script:WORKINGDIR -ChildPath "config"

[IO.FileInfo]$Script:ENVFILE          = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env"
[IO.FileInfo]$Script:COMPOSEFILE      = Join-Path -Path $Script:WORKINGDIR -ChildPath "compose.yaml"
[IO.DirectoryInfo]$Script:COMMONDIR   = $PSScriptRoot
[IO.FileInfo]$Script:COMMONENVFILE    = Join-Path -Path $Script:COMMONDIR -ChildPath ".env.common"
[IO.FileInfo]$Script:COMMONCONFIGFILE = Join-Path -Path $Script:COMMONDIR -ChildPath "../config.json"
[int]$Script:PUID = 568
[int]$Script:PGID = 568
[IO.DirectoryInfo]$Script:DATADIR     = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath "state"
[IO.DirectoryInfo]$Script:SECRETSDIR  = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath ".secrets"


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
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path,

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

    [string]$delimiter = " = "
    [IO.FileInfo]$temporaryFile = $null
    [Collections.Generic.List[string]]$inputLines = @()
    [Collections.Generic.List[string]]$outputLines = @()
    [string]$currentName = ""
    [string]$currentValue = ""
    [string]$currentComment = ""
    [string]$currentLeftover = ""
    [bool]$keyFound = $false
    [hashtable]$matches = @{}

    $inputLines = Get-Content -Path $Path -Encoding UTF8

    foreach ($line in $inputLines) {
        $currentName = ""
        $currentValue = ""
        $currentComment = ""
        $currentLeftover = ""

        if (($line -match '^\s*#') -or ($line -match '^\s*$')) { 
            # comment line starting with # or empty line
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
                $currentName = $matches.name
            }
            if ($matches.ContainsKey("leftover")) {
                $currentLeftover = $matches.leftover
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
                $newLine = $currentName + $delimiter + $Value
            }
            else {
                $newLine = $currentName + $delimiter + $currentValue
            }
        }
        else {
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
    Set-Content -Path $temporaryFile -Value $outputLines -Encoding UTF8
    if ($Path.Linktarget) {
        Move-Item -Path $temporaryFile -Destination $Path.LinkTarget -Force:$Force
    }
    else {
        Move-Item -Path $temporaryFile -Destination $Path -Force:$Force
    }
}

function Set-DockerSecret {
    [CmdletBinding(PositionalBinding=$false, DefaultParameterSetName="Value")]
    [OutputType([void])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]$Path,

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
        [ValidateRange(1,128)]
        [int]$Length = 32,

        [Parameter()]
        [switch]$Overwrite
    )

    [byte[]]$bytes = @()
    [IO.FileInfo]$secretFile = Join-Path -Path $Path.FullName -ChildPath $Name
    [IO.FileInfo]$temporaryFile = $null
    [string]$currentValue = ""
    
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
            chmod 600 $temporaryFile.FullName
        }
        Set-Content -Path $temporaryFile.FullName -Value $currentValue -Encoding UTF8 -NoNewLine

        New-Item -Path $secretFile.Directory -ItemType Directory -Force | Out-Null
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

    begin {
        [IO.FileSystemInfo[]]$items = @()
        [Collections.Generic.List[IO.DirectoryInfo]]$directories = @()
        [Collections.Generic.List[IO.FileInfo]]$files = @()
        [string]$directoryMode = ""
        [string]$fileMode = ""
        [int]$digit = 0

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
    }

    process {
        if (Test-Path -Path $Path) {
            if ((Get-Item $Path).PSIsContainer) {
                [IO.DirectoryInfo]$Path = Get-Item -Path $Path
            }
            else {
                [IO.FileInfo]$Path = Get-Item -Path $Path
            }
        }
        else {
            [IO.DirectoryInfo]$Path = New-Item -Path $Path -ItemType Directory -Force
        }
    
        $items = @($Path)
        if (($Path.PSIsContainer) -and $Recurse.IsPresent) {
            $items += Get-ChildItem -Path $Path -Force:$Force -Recurse
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
                $directories.FullName | xargs -r chmod $directoryMode
            }
            if ($files) {
                $files.FullName | xargs -r chmod $fileMode
            }
        }
    }
}

function Get-DockerCompose {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path
    )

    [string[]]$content = @()

    if (-not (Test-Path -Path $Path.FullName)) {
        throw "File $($Path.FullName) not found."
    }

    $content = docker compose -f $Path.FullName config
        #--no-consistency		Don't check model consistency - warning: may produce invalid Compose output
        #--no-env-resolution	Don't resolve service env files
        #--no-interpolate		Don't interpolate environment variables
        #--no-normalize		    Don't normalize compose model (convierte formatos cortos a largos)
        #--no-path-resolution	Don't resolve file paths
    if ($LASTEXITCODE) {
        throw "Unable to generate compose file: $($Error[0])"
    }   
    return [hashtable]($content | ConvertFrom-Yaml)
}

function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([Collections.Generic.List[string]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )
    [Collections.Generic.List[string]]$volumesList = @()


    foreach ($service in $Data.services) {
        #Write-Host "Servicio: $($service.Keys)"
        foreach ($serviceName in $service.Keys ) {
            if ($service.$serviceName.Keys -Contains "volumes") {
                #Write-host "Volumen encontrado"
                #$service.$serviceName.volumes.source
                #$volumesList.AddRange([string[]]$service.$serviceName.volumes.source)
                $volumesList += $service.$serviceName.volumes.source
            }
        }
    }
    return $volumesList
}

function Test-DockerSubmodule {
    [CmdletBinding()]
    [OutputType([bool])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path
    )

    if ($Path.DirectoryName -like "$Script:INCLUDEDIR/*") {
        return $true
    }
    else {
        return $false
    }
}

function Set-DockerConfiguration {

    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [IO.FileInfo]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name
    )

    [IO.FileInfo]$configFile = $null
    $Path
    Join-Path -Path $Script:INCLUDEDIR -ChildPath $Path.Directory.BaseName -AdditionalChildPath $ScriptDir:CONFIGDIR.BaseName
    Join-Path -Path $configFile.FullName -ChildPath $Name
    Join-Path -Path $Script:CONFIGDIR -ChildPath $Name
    Join-Path -Path $Script:DATADIR -ChildPath $Path.Directory.BaseName -AdditionalChildPath $Name
    if (Test-DockerSubmodule -Path $Path.DirectoryName) {
        Write-Host "Es submodulo."
        $configFile = Join-Path -Path $Script:INCLUDEDIR -ChildPath $Path.Directory.BaseName -AdditionalChildPath $ScriptDir:CONFIGDIR.BaseName
        $configFile = Join-Path -Path $configFile.FullName -ChildPath $Name
    }
    else {
        Write-Host "No es submodulo."
        $configFile = Join-Path -Path $Script:CONFIGDIR -ChildPath $Name
    }
    New-Item -Path (Join-Path -Path $Script:DATADIR -ChildPath $Path.Directory.BaseName -AdditionalChildPath $Name) -ItemType SymbolicLink -Value $configFile -Force | Out-Null
}


## EXPORT COMPONENTES ##########################################################
Export-ModuleMember -Function * -Variable * #-Module *

Write-Host "Finishing $PSCommandPath"
