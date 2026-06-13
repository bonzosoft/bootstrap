#!/usr/bin/env pwsh

$InformationPreference = 'Continue'

[IO.DirectoryInfo]$WorkingDir = (Get-Location).Path
[IO.DirectoryInfo]$RepoDir    = Join-Path -Path $WorkingDir -ChildPath @("common")
[IO.DirectoryInfo]$ConfigDir  = Join-Path -Path $WorkingDir -ChildPath @(".config")
[IO.FileInfo]$HostConfigFile  = Join-Path -Path $ConfigDir  -ChildPath @("host", "config.json")
[string]$BranchName = "pruebas"

Write-Host "Bienvenido al asistente de instalación. Pulsa una tecla para continuar..."
Read-Host

gh auth login

if (Test-Path $RepoDir) {
    Remove-Item -Path $RepoDir -Recurse -Force
}
git clone --branch $BranchName --single-branch https://github.com/bonzosoft/$($RepoDir.Name).git
foreach ($item in @("install", "cmd")) {
    ln -snf (Join-Path -Path $RepoDir -ChildPath @("$item.ps1") ) (Join-Path -Path $WorkingDir -ChildPath @("$item"))
    chmod +x (Join-Path -Path $WorkingDir -ChildPath @("$item"))
}
