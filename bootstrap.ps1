#!/usr/bin/env pwsh

$InformationPreference = 'Continue'

[string]$BranchName = "pruebas"

[IO.DirectoryInfo]$WorkingDir = (Get-Location).Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @("common")
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")

Write-Host ""
Write-Host "Bienvenido al asistente de instalación (v0.1.12). Pulsa una tecla para continuar..."
Read-Host

$env:GH_CONFIG_DIR=(Join-Path -Path $ConfigDir -ChildPath @("gh"))
$null = gh config set prompt disabled 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error $errorMessage
}

if ((gh auth status 2>&1 variable:errorMessage) -ne 0) {
    gh auth login --git-protocol "https" --hostname "github.com" --web
    if ($LASTEXITCODE) {
        Write-Error $errorMessage
    }
}
if (Test-Path $RepoDir) {
    Remove-Item -Path $RepoDir -Recurse -Force
}
$null = gh auth setup-git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error $errorMessage
}
$null = git clone --branch $BranchName --single-branch https://github.com/bonzosoft/$($RepoDir.Name).git 2> variable:errorMessage
if ($LASTEXITCODE) {
    Write-Error $errorMessage
}
foreach ($item in @("install", "cmd")) {
    ln -snf (Join-Path -Path $RepoDir -ChildPath @("$item.sh") ) (Join-Path -Path $WorkingDir -ChildPath @("$item"))
    chmod +x (Join-Path -Path $WorkingDir -ChildPath @("$item"))
}
