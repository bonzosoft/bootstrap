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
[string]$GitProtocol      = "https"
[string]$GitProvider      = "github.com"
[string]$OrganizationName = "bonzosoft"
[string]$RepositoryName   = "common"
[string]$BranchName       = "pruebas"

[IO.DirectoryInfo]$WorkingDir = $PWD.Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @($RepositoryName)
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")

$env:GH_CONFIG_DIR=(Join-Path -Path $ConfigDir -ChildPath @("gh"))
$env:GIT_TERMINAL_PROMPT = 0


### SCRIPT #####################################################################
Clear-Host
Write-Host ""
Write-Host "############################################"
Write-Host "###           BOOTSTRAP SCRIPT           ###"
Write-Host "###   --------------------------------   ###"
Write-Host "###         [Version:   0. 1.24]         ###"
Write-Host "############################################"
Write-Host ""

# disable user prompt
$null = gh config set prompt disabled 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

# check gh session 
Write-Information -MessageData "Checking ${GitProvider} session." -InformationAction 'Continue'
$null = gh auth status *> $null
if ($LASTEXITCODE) {
    gh auth login --git-protocol $GitProtocol --hostname $GitProvider --web
}

# propagate auth to git
Write-Information -MessageData "Configuring ${GitProvider} session for Git." -InformationAction 'Continue'
$null = gh auth setup-git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

# remove previous version
if (Test-Path -Path $RepoDir) {
    Write-Information -MessageData "Removing previous version." -InformationAction 'Continue'
    Remove-Item -Path $RepoDir -Recurse -Force | Out-Null
}

# get new version
Write-Information -MessageData "Cloning repository ${OrganizationName}/${RepositoryName}." -InformationAction 'Continue'
$null = git clone --branch $BranchName --single-branch "${GitProtocol}://${GitProvider}/${OrganizationName}/${RepositoryName}.git" 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

foreach ($item in @("install", "cmd")) {
    Write-Information -MessageData "Adding link '${item}'." -InformationAction 'Continue'
    ln -snf (Join-Path -Path $RepoDir -ChildPath @($item + ".sh") ) (Join-Path -Path $WorkingDir -ChildPath @($item))
    chmod +x (Join-Path -Path $WorkingDir -ChildPath @($item))
}
