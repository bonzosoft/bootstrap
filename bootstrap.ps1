#!/usr/bin/env pwsh


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$VerbosePreference     = 'Continue'
$InformationPreference = 'Continue'


### LOAD MODULES ###############################################################
$verboseBackup = $VerbosePreference
$modules = @(
    # nop

)

$VerbosePreference = 'SilentlyContinue'
foreach ($module in $modules) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath $module)
}
$VerbosePreference = $verboseBackup


### CONFIGURATION ##############################################################
[string]$GitProvider      = "github.com"
[string]$OrganizationName = "bonzosoft"
[string]$RepositoryName   = "common"
[string]$BranchName       = "pruebas"

[IO.DirectoryInfo]$WorkingDir = $PWD.Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @($RepositoryName)
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")

$env:GH_CONFIG_DIR=(Join-Path -Path $ConfigDir -ChildPath @("gh"))
$env:GIT_TERMINAL_PROMPT = 0

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "############################################"
    Write-Host "###           BOOTSTRAP SCRIPT           ###"
    Write-Host "###   --------------------------------   ###"
    Write-Host "###         [Version:   0. 1.20]         ###"
    Write-Host "############################################"
    Write-Host ""
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

# check gh session 
$null = gh auth status 2> variable:errorMessage
if ($LASTEXITCODE) {
    gh auth login --git-protocol "https" --hostname $GitProvider --web
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
}

# propagate auth to git
$null = gh auth setup-git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

# remove previous version
if (Test-Path $RepoDir) {
    Remove-Item -Path $RepoDir -Recurse -Force
}

# get new version
$null = git clone --branch $BranchName --single-branch https://$GitProvider/$OrganizationName/$RepositoryName.git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

foreach ($item in @("install", "cmd")) {
    ln -snf (Join-Path -Path $RepoDir -ChildPath @("$item.sh") ) (Join-Path -Path $WorkingDir -ChildPath @("$item"))
    chmod +x (Join-Path -Path $WorkingDir -ChildPath @("$item"))
}
