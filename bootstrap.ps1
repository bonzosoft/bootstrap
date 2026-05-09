#!/usr/bin/env pwsh

[CmdletBinding(DefaultParameterSetName = "TUI")]
[OutputType([void])]

param(
    [Parameter(ParameterSetName = "TUI")]
    [switch]$Menu,

    [Parameter(Mandatory, ParameterSetName = "Login")]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Login,

    [Parameter(Mandatory, ParameterSetName = "Logout")]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Logout,

    [Parameter(Mandatory, ParameterSetName = "Pull")]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Pull,

    [Parameter(Mandatory, ParameterSetName = "Start")]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Start,

    [Parameter(Mandatory, ParameterSetName = "Stop")]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Stop,

    [Parameter(Mandatory, ParameterSetName = "Realm")]
    [ValidateSet("prod", "dev")]
    [string]$Realm,

    [Parameter(Mandatory, ParameterSetName = "Help")]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================
# Constants
# =========================
[string]$Script:GITHOSTNAME = "github.com"
[int]$PUID = 568
[int]$PGID = 568
[IO.DirectoryInfo]$Script:COMMONDIR = Join-Path -Path (Get-Location) -ChildPath "common"
[IO.FileInfo]$Script:CONFIGFILE = Join-Path -Path (Get-Location) -ChildPath ".config" -AdditionalChildPath "docker.config.json"

# =========================
# Helpers
# =========================
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERRO", "SUCC")]
        $Level,
        $Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $colors = @{
        INFO = "`e[36m"
        WARN = "`e[33m"
        ERRO = "`e[31m"
        SUCC = "`e[32m"
        RESET = "`e[0m"
    }

    if ($Message) {
        Write-Host "$Timestamp [$($colors[$Level])$Level$($colors.RESET)] $Message"
    }
    else {
        Write-Host "$Timestamp [$($colors[$Level])$Level$($colors.RESET)]"
    }
}

function Get-DockerPGID {
    [CmdletBinding()]
    [OutputType([int])]


    [string[]]$group = Get-Content "/host/etc/group" | Where-Object { $PSItem -match "^docker:" }

    if ($group.Count -lt 1) {
        throw "No 'docker' group has been found on host."
    }
    elseif ($group.Count -gt 1) {
        throw "More than one 'docker' group has been found on host." 
    }
    else {
        return [int]($group.Split(":")[2])
    }
}

function Get-DockerHostname {
    return Get-Content "/host/etc/hostname"
}

function Test-IsTruenas {
    return Test-Path "/host/etc/version"
}

# =========================
# Config
# =========================
function Get-Config {
    if (Test-Path $Script:CONFIGFILE) {
        return Get-Content $Script:CONFIGFILE | ConvertFrom-Json
    }

    Write-Log WARN "Generating new config..."

    $config = @{
        PUID        = $PUID
        PGID        = $PGID
        HOSTNAME    = Get-DockerHostname
        DOCKER_PGID = Get-DockerPGID
        TRUENAS     = Test-IsTruenas
        REALM       = "prod"
    }

    $config | ConvertTo-Json | Set-Content $Script:CONFIGFILE
    return $config
}

function Save-Config($config) {
    $config | ConvertTo-Json | Set-Content $Script:CONFIGFILE
}

function Set-Realm {
    param($Realm, $Config)

    $Config.REALM = $Realm
    Save-Config $Config
    Write-Log SUCC "Realm set to $Realm"
}

# =========================
# GitHub
# =========================
function Test-Repository {
    gh auth status *> $null
    return ($LASTEXITCODE -eq 0)
}

function Connect-Repository {
    
    Write-Log INFO "Checking GitHub authentication..."
    if (-not (Test-Repository)) {
        Write-Log INFO "Logging into GitHub..."
        gh auth login --hostname $Script:GITHOSTNAME --git-protocol https --web
        if ($LASTEXITCODE) {
            Write-Log ERRO "Login failed"
            return
        }
    }
    
    gh auth setup-git
    Write-Log SUCC "Login OK"
}

function Disconnect-Repository {
    if (-not (Test-Repository)) {
        Write-Log WARN "No active session"
        return
    }

    gh auth logout --hostname $Script:GITHOSTNAME
    Write-Log SUCC "Logged out"
}

function Get-GithubRepo {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Branch="main",

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Organization="bonzosoft"
    )

    if (-not (Test-Path "./$Name/.git")) {
        Write-Log INFO "Cloning $Name"
        gh repo clone "$Organization/$Name" "./$Name" -- --branch $Branch
        if ($LASTEXITCODE) {
            Write-Log ERRO "Clone failed"
            return
        }
    }

    Push-Location "./$Name"

    Write-Log INFO "Syncing $Name ($Branch)"
    #gh repo sync --branch $Branch --force

    git fetch origin
    git checkout $Branch
    git reset --hard origin/$Branch
    git clean -fd

    # Submódulos
    git submodule update --init --recursive

    if (Test-Path "onpull.ps1") {
        pwsh -File "onpull.ps1"
    }

    Pop-Location
    Write-Log SUCC "$Name ready"
}

# =========================
# Docker
# =========================
function Start-Compose($Name, $Config) {
    Push-Location "./$Name"

    bash "./predeploy"

    $project = if ($Config.TRUENAS) { "ix-$Name" } else { $Name }
    docker compose -p $project up -d

    Pop-Location
    Write-Log SUCC "$Name started"
}

function Stop-Compose($Name) {
    Push-Location "./$Name"
    docker compose down
    Pop-Location
    Write-Log SUCC "$Name stopped"
}

# =========================
# INIT
# =========================
Push-Location -Path $PSScriptRoot
git pull
Pop-Location

$Script:Config = Get-Config
write-host $PSCmdlet.ParameterSetName
switch ($PSCmdlet.ParameterSetName) {
    "TUI" {
        do {
            Clear-Host
    
            Write-Host "==========================================="
            Write-Host "===              MAIN MENU              ==="
            Write-Host "==========================================="
            Write-Host "Realm: $($Script:Config.REALM)"
            Write-Host ""
            Write-Host "  1. Login"
            Write-Host "  2. Set Realm"
            Write-Host "  3. Komodo Core pull"
            Write-Host "  4. Komodo Core start"
            Write-Host "  5. Komodo Periphery pull"
            Write-Host "  6. Komodo Periphery start"
            Write-Host "  7. Logout"
            Write-Host "  q. Exit"
            Write-Host ""
    
            switch (Read-Host "Option") {
                "1" { 
                    Connect-Repository
                }
                "2" {
                    Write-Host ""
                    Write-Host "Select realm:"
                    Write-Host ""
                    Write-Host "  1. Production"
                    Write-Host "  2. Development"
                    Write-Host "  q. Return"
                    Write-Host ""
                    
                    :whileloop do {
                        :switchloop switch (Read-Host "Option") {
                            "1" {
                                Set-Realm "prod" $Script:Config
                                $Script:Config = Get-Config
                                break whileloop
                            }
                            "2" {
                                Set-Realm "dev" $Script:Config
                                $Script:Config = Get-Config
                                break whileloop
                            }
                            "q" {
                                break whileloop
                            }
                            default {
                                break switchloop
                            }
                        }
                    } while ($true)
                }
                "3" {
                    if (-not (Test-Repository)) {
                        Write-Log ERRO "Login first"
                        break
                    }
                    Get-GithubRepo -Name "common" -Branch "main"
                    Get-GithubRepo -Name "komodo-core" -Branch "mongodb"
                    Read-Host
                }
                "4" {
                    [IO.DirectoryInfo]$folder = Join-Path -Path $PSScriptRoot -ChildPath "komodo-core"
                    if (Test-Path -Path $folder) {
                        docker compose `
                          --file (Join-Path -Path $folder -ChildPath "compose.yaml") `
                          --env-file (Join-Path -Path $folder -ChildPath ".env") `
                    }
                }
                "5" {
                    if (-not (Test-Repository)) {
                        Write-Log ERRO "Login first"
                        break
                    }
                    Get-GithubRepo -Name "common" -Branch "main"
                    Get-GithubRepo -Name "komodo-periphery" -Branch "main"
                    Read-Host
                }
                "7" {
                    Disconnect-Repository
                }
                "q" {
                    Clear-Host
                    exit
                }
            }
    
            Start-Sleep -MilliSeconds 250
        } while ($true)
    }
    "Realm" {
        Set-Realm -Realm $Realm -Config $Script:Config
        $Script:Config = Get-Config
    }
    "Login" {
        Connect-Repository  
    }
    "Logout" {
        Disconnect-Repository
    }
    "Pull" {
        Get-GithubRepo "common"
        Get-GithubRepo $Pull
    }
    "Start" {
        Start-Compose $Start $Script:Config
    }
    "Stop" {
        Stop-Compose $Stop
    }
    default {
        throw "Unknown parameter set name: $(PSCmdlet.ParameterSetName)"
    }
}

return
