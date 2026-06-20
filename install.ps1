#!/usr/bin/env pwsh


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference     = 'Continue'
$InformationPreference = 'Continue'


### LOAD MODULES ###############################################################
$verboseBackup = $VerbosePreference
$modules = @(
    "pwsh-Docker"
    "pwsh-Git"
)

$VerbosePreference = 'SilentlyContinue'
foreach ($module in $modules) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath @("modules", $module))
}
$VerbosePreference = $verboseBackup


### CONFIGURATION ##############################################################
[string]$GitProvider = "github.com"
[string]$GitNamespace = "bonzosoft"
[string]$commonGitRepository = "common"
[string]$commonGitBranch = "pruebas"
[string]$coreGitRepository = "komodo-core"
[string]$coreGitBranch = "main"
[string]$peripheryGitRepository = "komodo-periphery"
[string]$peripheryGitBranch = "main"

[IO.DirectoryInfo]$WorkingDir = $PWD.Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @("common")
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")

$env:GH_CONFIG_DIR=(Join-Path -Path $ConfigDir -ChildPath @("gh"))
$env:GIT_TERMINAL_PROMPT = 0

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "############################################"
    Write-Host "###            INSTALL SCRIPT            ###"
    Write-Host "###   --------------------------------   ###"
    Write-Host "###         [Version:     0.1.2]         ###"
    Write-Host "############################################"
    Write-Host ""
}

function Write-MainMenu {
    Write-Host "Tenant: $($Script:Config.Tenant)"
    Write-Host ""
    Write-Host "  1. Login"
    Write-Host "  2. Set Tenant"
    Write-Host "  3. Set Backup Network"
    write-Host "  4. Pull Common"
    Write-Host "  5. Pull Komodo Core"
    Write-Host "  6. Start Komodo Core"
    Write-Host "  7. Pull Komodo Periphery"
    Write-Host "  8. Start Komodo Periphery"
    Write-Host "  9. Logout"
    Write-Host "  q. Exit"
    Write-Host ""
}

### SCRIPT #####################################################################

& { # TUI
    trap { 
        # traps any throw during the text UI
        Write-Error -Message "Trapped: $PSItem"
        Read-Host | Out-Null
        continue
    }

    Clear-Host
    Write-Header
    Write-Host "Press any key to continue..."
    Read-Host | Out-Null
    
    do {
        Clear-Host
        Write-Header
        Write-MainMenu
        switch (Read-Host -Prompt "Option") {
            "1" { 
                Write-Information -MessageData "Checking authentication."
                if (-not (Test-GitProviderSession -Provider $GitProvier)) {
                    Write-Information -MessageData "Starting login procedure."
                    Start-GitProviderSession -Provider $GitProvider
                }
                else {
                    Write-Information -MessageData "Session data is correct."
                }
                Write-Information -MessageData "Sending ${GitProvider} session to Git."
                Assert-GitProviderSession -Provider $GitProvider
                Write-Information -MessageData "Login succeeded."
            }
            "2" {
                Write-Host ""
                Write-Host "Select tenant:"
                Write-Host ""
                Write-Host "  1. AST"
                Write-Host "  2. BonzoSoft"
                Write-Host "  q. Return"
                Write-Host ""
                
                do {
                    switch (Read-Host "Option") {
                        "1" {
                            Set-Tenant -NewTenant "AST" -Config $Script:Config
                            $Script:Config = Get-Config
                        }
                        "2" {
                            Set-Tenant -NewTenant "BonzoSoft" -Config $Script:Config
                            $Script:Config = Get-Config
                        }
                        "q" {
                            # nop
                        }
                        default {
                            Write-Information -MessageData "Unknown option '$PSItem'."
                            continue whileloop
                        }
                    }
                    break
                } while ($true)
            }
            "3" {
                # Comprobación de la red Docker
                docker network inspect backup *> $null
                if ($LASTEXITCODE) {
                    $null = docker network create backup 2> variable:errorMessage
                    if ($LASTEXITCODE) {
                        throw $errroMessage
                        break
                    }
                    else {
                        Write-Information -MessageData "Network creation succeeded."
                    }
                }
            }
            "4" {
                if (-not (Test-GitProviderSession -Provider $GitProvider)) {
                    throw "Must be logged in to proceed."
                    break
                }
                Import-GitRepository -Provider $GitProvider -Namespace $GitNamespace -Name $commonGitRepository -Branch $commonGitBranch
            }
            "5" {
                if (-not (Test-GitProviderSession -Provider $GitProvider)) {
                    throw "Must be logged in to proceed."
                    break
                }
                Import-GitRepository -Provider $GitProvider -Namespace $GitNamespace -Name $coreGitRepository -Branch $coreGitBranch
            }
            "6" {
                [IO.DirectoryInfo]$folder = Join-Path -Path $PSScriptRoot -ChildPath "coreGitRepository"
                if (Test-Path -Path $folder) {
                    # Corregido: Se añadió la acción 'up -d' al comando
                    docker compose `
                      --file (Join-Path -Path $folder -ChildPath "compose.yaml") `
                      --env-file (Join-Path -Path $folder -ChildPath ".env") `
                      up -d
                } else {
                    Write-Log ERRO "Komodo Core directory not found. Pull it first."
                }
            }
            "7" {
                if (-not (Test-GitProviderSession -Provider $GitProvider)) {
                    throw "Must be logged in to proceed."
                    break
                }
                Import-GitRepository -Provider $GitProvider -Namespace $GitNamespace -Name $peripheryGitRepository -Branch $peripheryGitBranch
            }
            "7" {
                [IO.DirectoryInfo]$folder = Join-Path -Path $PSScriptRoot -ChildPath "coreGitRepository"
                if (Test-Path -Path $folder) {
                    docker compose `
                      --file (Join-Path -Path $folder -ChildPath "compose.yaml") `
                      --env-file (Join-Path -Path $folder -ChildPath ".env") `
                      up -d
                } else {
                    Write-Log ERRO "Komodo Periphery directory not found. Pull it first."
                }
            }
            "8" {
                Stop-GitProviderSession -Provider $GitProvider
            }
            "9" {
                Clear-Host
                exit
            }
        }
    
        Start-Sleep -MilliSeconds 250
    } while ($true)
    
}






# assert config dir
if (-not (Test-Path -Path $configDir)) { 
    New-Item -Path $configDir -ItemType 'Directory' | Out-Null
}

# disable user prompt
$null = gh config set prompt disabled 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
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


switch ($PSCmdlet.ParameterSetName) {
    "TUI" {
        do {
            Clear-Host
            Write-Host ""
            Write-Host "########################################"
            Write-Host "###            MAIN MENU             ###"
            Write-Host "########################################"

    
            
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