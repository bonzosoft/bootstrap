#!/usr/bin/env pwsh

$InformationPreference = 'Continue'

[string]$BranchName = "pruebas"

[IO.DirectoryInfo]$WorkingDir = (Get-Location).Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @("common")
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")

Write-Host ""
Write-Host "Bienvenido al asistente de instalación (v0.1.7). Pulsa una tecla para continuar..."
Read-Host

$env:GH_CONFIG_DIR=(Join-Path -Path $ConfigDir -ChildPath @("gh"))
$null = Invoke-Command -FilePath gh -ArgumentList @(config set prompt disabled) 
if (-not (gh auth status)) {
    gh auth login --git-protocol "https" --hostname "github.com" --web
    
}
if (Test-Path $RepoDir) {
    Remove-Item -Path $RepoDir -Recurse -Force
}
gh auth setup-git
git clone --branch $BranchName --single-branch https://github.com/bonzosoft/$($RepoDir.Name).git
foreach ($item in @("install", "cmd")) {
    ln -snf (Join-Path -Path $RepoDir -ChildPath @("$item.sh") ) (Join-Path -Path $WorkingDir -ChildPath @("$item"))
    chmod +x (Join-Path -Path $WorkingDir -ChildPath @("$item"))
}
