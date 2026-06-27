#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    <#
    # ==========================================================================
    # GENERAL CONFIGURATION
    # ==========================================================================
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Continue'
    $InformationPreference = 'Continue'
    $VerbosePreference     = 'Continue'


    # ==========================================================================
    # MODULES
    # ==========================================================================
    [string[]]$modules = @(
        "pwsh-Docker"
        "pwsh-Git"
    )

    New-Variable -Name verboseBackup -Value ([string]$VerbosePreference) 
    $VerbosePreference = 'SilentlyContinue'
    foreach ($module in $modules) {
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath @("modules", $module))
    }
    $VerbosePreference = $verboseBackup
    Remove-Variable -Name verboseBackup


    # ==========================================================================
    # CONSTANTS
    # ==========================================================================
    [string]$scriptVersion          = "00.01.16"
    [string[]]$errorMessage         = @()
    [IO.DirectoryInfo]$workingDir   = $PWD.Path
    [IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $workingDir -ChildPath @(".config", "git")
    [IO.FileInfo]$dockerConfigFile  = Join-Path -Path $workingDir -ChildPath @(".config", "docker.json")
    [string]$gitProtocol            = "https"
    [string]$gitProvider            = "github.com"
    [string]$gitNamespace           = "bonzosoft"
    [string]$commonRepository       = "common"
    [string]$commonBranch           = "main"
    [IO.DirectoryInfo]$commonDir    = Join-Path -Path $workingDir -ChildPath @($commonRepository)
    [string]$coreRepository         = "komodo-core"
    [string]$coreBranch             = "main"
    [IO.DirectoryInfo]$coreDir      = Join-Path -Path $workingDir -ChildPath @($coreRepository)
    [string]$peripheryRepository    = "komodo-periphery"
    [string]$peripheryBranch        = "main"
    [IO.DirectoryInfo]$peripheryDir = Join-Path -Path $workingDir -ChildPath @($peripheryRepository)

    $env:GH_CONFIG_DIR = $gitConfigDir
    $env:GIT_TERMINAL_PROMPT = 0
    #>

    # ==========================================================================
    # LOAD COMMON ASSETS
    # ==========================================================================
    . (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


    # ==========================================================================
    # FUNCTIONS
    # ==========================================================================
    function Write-Header($Configuration) {
        Clear-Host
        Write-Host ""
        Write-Host "############################################"
        Write-Host "###            INSTALL SCRIPT            ###"
        Write-Host "###   --------------------------------   ###"
        Write-Host "###         [Version:  ${scriptVersion}]         ###"
        Write-Host "############################################"
        Write-Host "Tenant: $($Configuration.Tenant)"
        Write-Host ""
    }

    function Write-MainMenu() {
        Write-Host "Select an option:"
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
        Write-Host ""
        Write-Host "  q. Exit"
        Write-Host ""
    }

    function Write-TenantMenu() {
        Write-Host "Select an option:"
        Write-Host ""
        Write-Host "  1. AST"
        Write-Host "  2. BonzoSoft"
        Write-Host ""
        Write-Host "  q. Return"
        Write-Host ""
    }
}

process {
    trap {
        Get-Error -InputObject $PSItem | Format-List * -Force
        Read-Host | Out-Null
    }
    
    # ==========================================================================
    # SCRIPT
    # ==========================================================================
    [hashtable]$configHashtable = Read-GitConfig -Path $dockerConfigFile
    [string]$repository = ""
    [string]$branch = ""
    [IO.DirectoryInfo]$repoDir = $null
    
    New-Variable -Name errorActionBackup -Value ([string]$ErrorActionPreference) 
    $ErrorActionPreference = 'Continue'
    do {
        Clear-Host
        $configHashtable = Read-GitConfig -Path $dockerConfigFile
        Write-Header -Configuration $configHashtable
        Write-MainMenu
        switch (Read-Host -Prompt "Option") {
            "1" { 
                Write-Information -MessageData "Checking authentication."
    
                if (-not (Test-GitProviderSession -Provider $gitProvider -GithubCLI)) {
                    Write-Information -MessageData "Starting login procedure."
                    Start-GitProviderSession -Provider $gitProvider -Protocol $gitProtocol
                }
                else {
                    Write-Information -MessageData "Github CLI credentials are correct."
                }
    
                if (-not (Test-GitProviderSession -Provider $gitProvider -Git)) {
                    Write-Information -MessageData "Sending $gitProvider session to Git."
                    Assert-GitProviderSession -Provider $gitProvider
                }
                else {
                    Write-Information -MessageData "Git credentials are correct."       
                }
                
                Write-Information -MessageData "Login succeeded."
            }
            "2" {
                Clear-Host
                Write-Header -Config $configHashtable
                Write-TenantMenu
                
                :tenantDoWhile do {
                    switch (Read-Host "Option") {
                        "1" {
                            $configHashtable.Tenant = "AST"
                            Write-GitConfig -Path $dockerConfigFile -Value $configHashtable
                            $configHashtable = Read-GitConfig -Path $dockerConfigFile
    
                            break tenantDoWhile
                        }
                        "2" {
                            $configHashtable.Tenant = "BonzoSoft"
                            Write-GitConfig -Path $dockerConfigFile -Value $configHashtable
                            $configHashtable = Read-GitConfig -Path $dockerConfigFile
    
                            break tenantDoWhile
                        }
                        "q" {
                            break tenantDoWhile
                        }
                        default {
                            continue tenantDoWhile
                        }
                    }
                } while ($true)
            }
            "3" {
                $null = docker network inspect backup 2> $null
                if ($LASTEXITCODE) {
                    $null = docker network create backup 2> variable:errorMessage
                    if ($LASTEXITCODE) {
                        Write-Error -Message $errroMessage
                    }
                    else {
                        Write-Information -MessageData "Network creation succeeded."
                    }
                }
                else {
                    Write-Information -MessageData "Network already exists."
                }
            }
            {$PSItem -in @("4", "5", "7")} {
                if (-not (Test-GitProviderSession -Provider $gitProvider -GithubCLI -Git)) {
                    Write-Error -Message "Please log in to continue."
                    continue
                }
    
                if (-not $configHashtable.Tenant) {
                    Write-Error -Message "Missing tenant config."
                    continue
                }
    
                switch ($PSItem) {
                    "4" {
                        $repository = $commonRepository
                        $branch = $commonBranch
                    }
                    "5" {
                        $repository = $coreRepository
                        $branch = $coreBranch
                    }
                    "7" {
                        $repository = $peripheryRepository
                        $branch = $peripheryBranch
                    }
                    default {
                        throw "Unexpected option."
                    }
                }
                Import-GitRepository -Provider $gitProvider -Protocol $gitProtocol -Namespace $gitNamespace -Repository $repository -Branch $branch -Force
    
                if ($PSItem -eq "4") {
                    foreach ($item in @("install", "cmd")) {
                        Write-Information -MessageData "Adding link '${item}'."
                        ln -snf (Join-Path -Path $commonDir -ChildPath @("${item}.sh")) (Join-Path -Path $workingDir -ChildPath @($item))
                        chmod +x (Join-Path -Path $workingDir -ChildPath @($item))
                    }
                }
            }
    
            {$PSItem -in @("6", "8")} {
                switch ($PSItem) {
                    "6" {
                        $repository = $coreRepository
                        $branch = $coreBranch
                        $repoDir = $coreDir
                    }
                    "8" {
                        $repository = $peripheryRepository
                        $branch = $peripheryBranch
                        $repoDir = $peripheryDir
                    }
                    default {
                        throw "Unexpected option."
                    }
                }
    
                Push-Location -Path $repoDir
                    docker compose up -d 2> variable:errorMessage
                    if ($LASTEXITCODE) {
                        Write-Error -Message $errorMessage
                    }
                Pop-Location
            }
            "9" {
                Stop-GitProviderSession -Provider $gitProvider
            }
            "q" {
                Clear-Host
                exit 0
            }
            default {
                continue
            }
        }
        Write-Information -MessageData ""
        Write-Information -MessageData "Press any key to continue..."
        Read-Host | Out-Null
    } while ($true)
    $ErrorActionPreference = $errorActionBackup
    Remove-Variable -Name errorActionBackup
}

end {
    # nop
}
