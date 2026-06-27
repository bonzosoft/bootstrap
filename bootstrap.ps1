#!/usr/bin/env pwsh


# ==============================================================================
# GENERAL CONFIGURATION
# ==============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$VerbosePreference     = 'Continue'


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
# CONSTANTS
# ==============================================================================
[string[]]$errorMessage      = @()
[string]$gitProtocol         = "https"
[string]$gitProvider         = "github.com"
[string]$gitNamespace        = "bonzosoft"
[string]$commonRepository    = "common"
[string]$commonBranch        = "main"
#[string]$coreRepository      = "komodo-core"
#[string]$coreBranch          = "main"
#[string]$peripheryRepository = "komodo-periphery"
#[string]$peripheryBranch     = "main"

[IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $PWD -ChildPath @(".config", "git")
#[IO.FileInfo]$dockerConfigFile  = Join-Path -Path $PWD -ChildPath @(".config", "docker.json")
[IO.DirectoryInfo]$commonDir    = Join-Path -Path $PWD -ChildPath @($commonRepository)
#[IO.DirectoryInfo]$coreDir      = Join-Path -Path $PWD -ChildPath @($coreRepository)
#[IO.DirectoryInfo]$peripheryDir = Join-Path -Path $PWD -ChildPath @($peripheryRepository)

$env:GH_CONFIG_DIR = $gitConfigDir
$env:GIT_TERMINAL_PROMPT = 0


# ==============================================================================
# SCRIPT
# ==============================================================================
Clear-Host
Write-Host ""
Write-Host "############################################"
Write-Host "###           BOOTSTRAP SCRIPT           ###"
Write-Host "###   --------------------------------   ###"
Write-Host "###         [Version:  00.01.28]         ###"
Write-Host "############################################"
Write-Host ""

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
    ln -snf (Join-Path -Path $commonDir -ChildPath @("${item}.sh")) (Join-Path -Path $PWD -ChildPath @($item))
    chmod +x (Join-Path -Path $PWD -ChildPath @($item))
}

Write-Information -MessageData ""
Write-Information -MessageData "Press any key to continue..."
Read-Host | Out-Null
