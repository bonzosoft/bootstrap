#!/usr/bin/env pwsh


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
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
[IO.DirectoryInfo]$configDir  = Join-Path -Path $PWD -ChildPath @(".config")
[IO.FileInfo]$configFile = Join-Path -Path $configDir -ChildPath @("host", "config.json")

$env:GH_CONFIG_DIR=(Join-Path -Path $configDir -ChildPath @("gh"))
$env:GIT_TERMINAL_PROMPT = 0

[string]$gitProvider = "github.com"
[string]$gitNamespace = "bonzosoft"
[string]$commonGitRepository = "common"
[string]$commonGitBranch = "pruebas"
[string]$coreGitRepository = "komodo-core"
[string]$coreGitBranch = "main"
[string]$peripheryGitRepository = "komodo-periphery"
[string]$peripheryGitBranch = "main"


function Write-Header($Config) {
    Clear-Host
    Write-Host ""
    Write-Host "############################################"
    Write-Host "###            INSTALL SCRIPT            ###"
    Write-Host "###   --------------------------------   ###"
    Write-Host "###         [Version:     0.1.6]         ###"
    Write-Host "############################################"
    Write-Host "Tenant: $($Config.Tenant)"
    Write-Host ""
}

function Write-MainMenu() {
    Write-Host "Select option:"
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

function Write-TenantMenu() {
    Write-Host "Select tenant:"
    Write-Host ""
    Write-Host "  1. AST"
    Write-Host "  2. BonzoSoft"
    Write-Host "  q. Return"
    Write-Host ""
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
[string]$errroMessage = ""
[hashtable]$config = Read-GitConfig -Path $configFile

### SCRIPT #####################################################################

& { # TUI
    trap { 
        # traps any throw during the text UI
        Write-Error -Message "Trapped: $PSItem"
        Read-Host | Out-Null
        continue
    }

    do {
        Clear-Host
        Write-Header -Config $config
        Write-MainMenu
        switch (Read-Host -Prompt "Option") {
            "1" { 
                Write-Information -MessageData "Checking authentication."
                if (-not (Test-GitProviderSession -Provider $gitProvider)) {
                    Write-Information -MessageData "Starting login procedure."
                    Start-GitProviderSession -Provider $gitProvider
                }
                else {
                    Write-Information -MessageData "Session data is correct."
                }
                Write-Information -MessageData "Sending $gitProvider session to Git."
                Assert-GitProviderSession -Provider $gitProvider
                Write-Information -MessageData "Login succeeded."
            }
            "2" {
                Clear-Host
                Write-Header -Config $config
                Write-TenantMenu
                
                do {
                    switch (Read-Host "Option") {
                        "1" {
                            $config.Tenant = "AST"
                            Write-GitConfig -Path $configFile -Data $Config
                            $config = Read-GitConfig -Path $configFile
                        }
                        "2" {
                            $config.Tenant = "BonzoSoft"
                            Write-GitConfig -Path $configFile -Data $Config
                            $config = Read-GitConfig -Path $configFile
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
                        Write-Error -Message $errroMessage
                        break
                    }
                    else {
                        Write-Information -MessageData "Network creation succeeded."
                    }
                }
            }
            "4" {
                if (-not (Test-GitProviderSession -Provider $gitProvider)) {
                    Write-Error -Message "Must be logged in to proceed."
                    continue
                }
                Import-GitRepository -Provider $gitProvider -Namespace $GitNamespace -Repository $commonGitRepository -Branch $commonGitBranch -Force
            }
            "5" {
                if (-not (Test-GitProviderSession -Provider $gitProvider)) {
                    Write-Error -Message "Must be logged in to proceed."
                    continue
                }
                Import-GitRepository -Provider $gitProvider -Namespace $GitNamespace -Repository $coreGitRepository -Branch $coreGitBranch -Force
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
                if (-not (Test-GitProviderSession -Provider $gitProvider)) {
                    Write-Error -Message "Must be logged in to proceed."
                    continue
                }
                Import-GitRepository -Provider $gitProvider -Namespace $GitNamespace -Repository $peripheryGitRepository -Branch $peripheryGitBranch -Force
            }
            "8" {
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
            "9" {
                Stop-GitProviderSession -Provider $gitProvider
            }
            "q" {
                Clear-Host
                exit 0
            }
        }
        Start-Sleep -MilliSeconds 250
    } while ($true)

}
