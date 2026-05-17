#!/usr/bin/env pwsh

### SINGLETON ##################################################################
$singleton = ([IO.FileInfo]$PSCommandPath).BaseName.Replace(".","_").ToUpper()
if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
}
Write-Information -Message "Loading script '$PSCommandPath'."


### SCRIPT CONFIGURATION #######################################################
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


### LOAD MODULES ###############################################################
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "pwsh-Docker")


### LOAD CONTEXT ###############################################################
Set-DockerContext -Name WorkingDir  -Value ([IO.DirectoryInfo](Get-Location).Path)
Set-DockerContext -Name ConfigDir   -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "config"))
Set-DockerContext -Name IncludeDir  -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "include"))
Set-DockerContext -Name ComposeFile -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "compose.yaml"))
Set-DockerContext -Name DotEnvFile  -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath ".env"))

Set-DockerContext -Name ProjectName -Value ([string]$Script:Context.WorkingDir.BaseName)
Set-DockerContext -Name DataDir     -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:Context.ProjectName))
Set-DockerContext -Name SecretsDir  -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.DataDir -ChildPath ".secrets"))

Set-DockerContext -Name Realm       -Value (Get-Content -Path (Join-Path -Path $Script:Context.WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json).REALM
Set-DockerContext -Name Hostname    -Value (Get-DockerHostname)

Set-DockerContext -Name PUID        -Value ([int]568)
Set-DockerContext -Name PGID        -Value ([int]568)

if ($Script.Context.Realm -eq "prod") {
    Set-DockerContext -Name SMTP_HOSTNAME          -Value "smtp.ast-ingenieria.com"
    Set-DockerContext -Name SMTP_PORT              -Value "587"
    Set-DockerContext -Name SMTP_USERNAME          -Value "soporte@ast-ingenieria.com"
    Set-DockerContext -Name SMTP_USERPASS          -Value "2908cc6d-93cc-4ca2-997f-e668edfa890d"
    Set-DockerContext -Name SMTP_PROVIDER_HOSTNAME -Value "smtp.gmail.com"
    Set-DockerContext -Name SMTP_PROVIDER_PORT     -Value "465"
    Set-DockerContext -Name SMTP_PROVIDER_USERNAME -Value "soporte@ast-ingenieria.com"
    Set-DockerContext -Name SMTP_PROVIDER_USERPASS -Value "ijac opkc encu oobu"
}
else {
    Set-DockerContext -Name Smtp                   -Value ""
    Set-DockerContext -Name SMTP_PORT              -Value "587"
    Set-DockerContext -Name Smtp                   -Value ""
    Set-DockerContext -Name Smtp                   -Value ""
    Set-DockerContext -Name SMTP_PROVIDER_HOSTNAME -Value "smtp.gmail.com"
    Set-DockerContext -Name SMTP_PROVIDER_PORT     -Value "465"
    Set-DockerContext -Name SMTP_PROVIDER_USERNAME -Value ""
    Set-DockerContext -Name SMTP_PROVIDER_USERPASS -Value ""
}


Write-Information -Message "Loaded script '$PSCommandPath'."
