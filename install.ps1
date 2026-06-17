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

    [Parameter(Mandatory, ParameterSetName = "Tenant")]
    [ValidateSet("ast", "bonzosoft")]
    [string]$Tenant,

    [Parameter(Mandatory, ParameterSetName = "Help")]
    [switch]$Help
)

### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$VerbosePreference     = 'Continue'
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
$verboseBackup = $VerbosePreference
$modules = @(
    "pwsh-Docker"
    "pwsh-Git"
)

$VerbosePreference = 'SilentlyContinue'
foreach ($module in $modules) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "modules/$module") -ErrorAction SilentlyContinue
}
$VerbosePreference = $verboseBackup

# =========================
# Constants
# =========================
[string]$Script:GITHOSTNAME = "github.com"
[IO.DirectoryInfo]$Script:COMMONDIR = Join-Path -Path $PSScriptRoot -ChildPath "common"
[IO.FileInfo]$Script:CONFIGFILE = Join-Path -Path $PSScriptRoot -ChildPath ".config/host/config.json"
$env:GIT_TERMINAL_PROMPT = "0" # Obliga a Git a fallar y devolver un error en vez de pedir usuario
$env:GH_CONFIG_DIR = Join-Path -Path ${PWD} -ChildPath ".config/gh"

# Asegurar que el directorio de configuración existe
$configDir = Split-Path $Script:CONFIGFILE -Parent
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }

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

# =========================
# Config
# =========================
function Get-Config {
    if (Test-Path $Script:CONFIGFILE) {
        return Get-Content $Script:CONFIGFILE | ConvertFrom-Json
    }

    Write-Log WARN "Generating new config..."
    $config = @{ Tenant = "ast" }
    
    $config | ConvertTo-Json | Set-Content $Script:CONFIGFILE
    return $config
}

function Save-Config($config) {
    $config | ConvertTo-Json | Set-Content $Script:CONFIGFILE
}

function Set-Tenant {
    param($NewTenant, $Config)

    $Config.Tenant = $NewTenant
    Save-Config $Config
    Write-Log SUCC "Realm set to $NewTenant"
}

# =========================
# Docker
# =========================
function Start-Compose($Name, $Config) {
    Push-Location "./$Name"

    if (Test-Path "./predeploy") { bash "./predeploy" }

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
$Script:Config = Get-Config

# 1. Aseguramos que el directorio de credenciales exista (variable definida en Constants)
if (-not (Test-Path $env:GH_CONFIG_DIR)) { 
    New-Item -ItemType Directory -Path $env:GH_CONFIG_DIR | Out-Null 
}

# 2. Usamos tus funciones para validar y preparar el entorno antes de actualizar el repo base
if (Test-Path -Path (Join-Path $PSScriptRoot ".git")) {
    Push-Location -Path $PSScriptRoot
    
    # Comprobamos si hay sesión activa con tu función
    if (Test-GitProvider) {
        # Integramos las credenciales usando tu función
        Assert-GitProvider 
        git pull
    } else {
        Write-Log WARN "Not authenticated. Initial repository update skipped."
    }
    
    Pop-Location
}

# Comprobación segura de la red Docker
docker network inspect backup > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    docker network create backup | Out-Null
}

switch ($PSCmdlet.ParameterSetName) {
    "TUI" {
        do {
            Clear-Host
    
            Write-Host "==========================================="
            Write-Host "===              MAIN MENU              ==="
            Write-Host "==========================================="
            Write-Host "Realm: $($Script:Config.Tenant)"
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
                    Connect-GitProvider
                    Pause
                }
                "2" {
                    Write-Host "`nSelect realm:`n"
                    Write-Host "  1. Production (ast)"
                    Write-Host "  2. Development (bonzosoft)"
                    Write-Host "  q. Return`n"
                    
                    :whileloop do {
                        :switchloop switch (Read-Host "Option") {
                            "1" {
                                Set-Tenant -NewTenant "ast" -Config $Script:Config
                                $Script:Config = Get-Config
                                break whileloop
                            }
                            "2" {
                                Set-Tenant -NewTenant "bonzosoft" -Config $Script:Config
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
                    if (-not (Test-GitProvider)) {
                        Write-Log ERRO "Login first"
                        Pause
                        break
                    }
                    Import-GitRepository -Namespace $Script:Config.Tenant -Name "common" -Branch "main"
                    ln -snf "$PSScriptRoot/common/cmd.sh" "$PSScriptRoot/cmd"
                    chmod +x "$PSScriptRoot/cmd"
                    
                    Import-GitRepository -Namespace $Script:Config.Tenant -Name "komodo-core" -Branch "main"
                    Pause
                }
                "4" {
                    [IO.DirectoryInfo]$folder = Join-Path -Path $PSScriptRoot -ChildPath "komodo-core"
                    if (Test-Path -Path $folder) {
                        # Corregido: Se añadió la acción 'up -d' al comando
                        docker compose `
                          --file (Join-Path -Path $folder -ChildPath "compose.yaml") `
                          --env-file (Join-Path -Path $folder -ChildPath ".env") `
                          up -d
                    } else {
                        Write-Log ERRO "Komodo Core directory not found. Pull it first."
                    }
                    Pause
                }
                "5" {
                    if (-not (Test-GitProvider)) {
                        Write-Log ERRO "Login first"
                        Pause
                        break
                    }
                    Import-GitRepository -Namespace $Script:Config.Tenant -Name "common" -Branch "main"
                    ln -snf "$PSScriptRoot/common/cmd.sh" "$PSScriptRoot/cmd"
                    chmod +x "$PSScriptRoot/cmd"
                    ln -snf "$PSScriptRoot/common/console.sh" "$PSScriptRoot/console"
                    chmod +x "$PSScriptRoot/console"

                    Import-GitRepository -Namespace $Script:Config.Tenant -Name "komodo-periphery" -Branch "main"
                    Pause
                }
                "6" {
                    [IO.DirectoryInfo]$folder = Join-Path -Path $PSScriptRoot -ChildPath "komodo-periphery"
                    if (Test-Path -Path $folder) {
                        docker compose `
                          --file (Join-Path -Path $folder -ChildPath "compose.yaml") `
                          --env-file (Join-Path -Path $folder -ChildPath ".env") `
                          up -d
                    } else {
                        Write-Log ERRO "Komodo Periphery directory not found. Pull it first."
                    }
                    Pause
                }
                "7" {
                    Disconnect-GitProvider
                    Pause
                }
                "q" {
                    Clear-Host
                    exit
                }
            }
    
            Start-Sleep -MilliSeconds 250
        } while ($true)
    }
    "Tenant" {
        # Corregido de "Realm" a "Tenant" y paso correcto de parámetros
        Set-Tenant -NewTenant $Tenant -Config $Script:Config
        $Script:Config = Get-Config
    }
    "Login" {
        Connect-GitProvider  
    }
    "Logout" {
        Disconnect-GitProvider
    }
    "Pull" {
        Import-GitRepository -Namespace $Script:Config.Tenant -Name "common"
        Import-GitRepository -Namespace $Script:Config.Tenant -Name $Pull
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