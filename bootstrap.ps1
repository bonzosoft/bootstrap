#!/usr/bin/env pwsh


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$VerbosePreference     = 'Continue'
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
$verboseBackup     = $VerbosePreference
$modules = @(
    # nop
)

$VerbosePreference = 'SilentlyContinue'
foreach ($module in $modules) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath @("modules", $module))
}
$VerbosePreference = $verboseBackup


### CONFIGURATION ##############################################################
[string]$BranchName = "pruebas"

[IO.DirectoryInfo]$WorkingDir = (Get-Location).Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @("common")
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")

$env:GH_CONFIG_DIR=(Join-Path -Path $ConfigDir -ChildPath @("gh"))
$env:GIT_TERMINAL_PROMPT = "0" # Obliga a Git a fallar y devolver un error en vez de pedir usuario

### SCRIPT #####################################################################
Clear-Host
Write-Host ""
Write-Host "[Version: 0.1.19]"
Write-Host ""
Write-Host "Bienvenido al asistente de instalación. Pulsa una tecla para continuar..."
Read-Host | Out-Null

Write-Information "El directorio de configuracion es:" -InformationAction 'Continue'
Write-Information (bash -c 'echo $GH_CONFIG_DIR') -InformationAction 'Continue'

# disable user prompt
$null = gh config set prompt disabled 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

# check gh session 
$null = gh auth status 2> variable:errorMessage
if ($LASTEXITCODE) {
    gh auth login --git-protocol "https" --hostname "github.com" --web #2> variable:errorMessage
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
$null = git clone --branch $BranchName --single-branch https://github.com/bonzosoft/$($RepoDir.Name).git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error -Message $errorMessage
}

foreach ($item in @("install", "cmd")) {
    ln -snf (Join-Path -Path $RepoDir -ChildPath @("$item.sh") ) (Join-Path -Path $WorkingDir -ChildPath @("$item"))
    chmod +x (Join-Path -Path $WorkingDir -ChildPath @("$item"))
}
