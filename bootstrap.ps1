#!/usr/bin/env pwsh


# ==============================================================================
# GENERAL CONFIGURATION
# ==============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$VerbosePreference     = 'Continue'


# ==============================================================================
# CONSTANTS
# ==============================================================================
[string]$scriptVersion          = "00.01.29"
[string[]]$errorMessage         = @()
[IO.DirectoryInfo]$workingDir   = $PWD.Path
[IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $workingDir -ChildPath @(".config", "git")
#[IO.FileInfo]$dockerConfigFile  = Join-Path -Path $workingDir -ChildPath @(".config", "docker.json")
[string]$gitProtocol            = "https"
[string]$gitProvider            = "github.com"
[string]$gitNamespace           = "bonzosoft"
[string]$commonRepository       = "common"
[string]$commonBranch           = "main"
[IO.DirectoryInfo]$commonDir    = Join-Path -Path $workingDir -ChildPath @($commonRepository)
#[string]$coreRepository         = "komodo-core"
#[string]$coreBranch             = "main"
#[IO.DirectoryInfo]$coreDir      = Join-Path -Path $workingDir -ChildPath @($coreRepository)
#[string]$peripheryRepository    = "komodo-periphery"
#[string]$peripheryBranch        = "main"
#[IO.DirectoryInfo]$peripheryDir = Join-Path -Path $workingDir -ChildPath @($peripheryRepository)

$env:GH_CONFIG_DIR = $gitConfigDir
$env:GIT_TERMINAL_PROMPT = 0


# ==============================================================================
# MODULES
# ==============================================================================
[string[]]$modules = @(
    # nop
    # nop
)

New-Variable -Name verboseBackup -Value ([string]$VerbosePreference) 
$VerbosePreference = 'SilentlyContinue'
foreach ($module in $modules) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath @("modules", $module))
}
$VerbosePreference = $verboseBackup
Remove-Variable -Name verboseBackup


# ==============================================================================
# FUNCTIONS
# ==============================================================================
function Write-Header($Configuration) {
    Clear-Host
    Write-Host ""
    Write-Host "############################################"
    Write-Host "###            INSTALL SCRIPT            ###"
    Write-Host "###   --------------------------------   ###"
    Write-Host "###         [Version:  ${scriptVersion}]         ###"
    Write-Host "############################################"
    Write-Host ""
}

# ==============================================================================
# SCRIPT
# ==============================================================================
Clear-Host
Write-Header

# check session for Github CLI 
Write-Information -MessageData "Checking session for ${gitProvider}."
$null = gh auth status *> $null
if ($LASTEXITCODE) {
    gh auth login --git-protocol $gitProtocol --hostname $gitProvider --web
}

# propagate session to git
Write-Information -MessageData "Asserting session for Git."
$null = gh auth setup-git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

# remove previous version
if (Test-Path -Path $commonDir) {
    Write-Information -MessageData "Removing previous version."
    Remove-Item -Path $commonDir -Recurse -Force | Out-Null
}

# get new version
Write-Information -MessageData "Cloning repository ${gitNamespace}/${commonRepository}."
$null = git clone --branch $commonBranch --single-branch "${gitProtocol}://${gitProvider}/${gitNamespace}/${commonRepository}.git" 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

# create links
foreach ($item in @("install", "cmd")) {
    Write-Information -MessageData "Adding link '${item}'."
    ln -snf (Join-Path -Path $commonDir -ChildPath @("${item}.sh")) (Join-Path -Path $workingDir -ChildPath @($item))
    chmod +x (Join-Path -Path $workingDir -ChildPath @($item))
}

Write-Information -MessageData ""
Write-Information -MessageData "Press any key to continue..."
Read-Host | Out-Null
