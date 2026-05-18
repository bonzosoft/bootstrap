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
. (Join-Path -Path ([IO.FileInfo]$PSCommandPath).DirectoryName -ChildPath "common.context.ps1")

#Set-DockerContext -Name WorkingDir  -Value ([IO.DirectoryInfo](Get-Location).Path)
#Set-DockerContext -Name ConfigDir   -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "config"))
#Set-DockerContext -Name IncludeDir  -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "include"))
#Set-DockerContext -Name ComposeFile -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath "compose.yaml"))
#Set-DockerContext -Name DotEnvFile  -Value ([IO.FileInfo](Join-Path -Path $Script:Context.WorkingDir -ChildPath ".env"))
#
#Set-DockerContext -Name ProjectName -Value ([string]$Script:Context.WorkingDir.BaseName)
#Set-DockerContext -Name DataDir     -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.WorkingDir.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:Context.ProjectName))
#Set-DockerContext -Name SecretsDir  -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Context.DataDir -ChildPath ".secrets"))
#
#Set-DockerContext -Name Tenant       -Value (Get-Content -Path (Join-Path -Path $Script:Context.WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json).TENANT
#Set-DockerContext -Name Hostname    -Value (Get-DockerHostname)
#
#Set-DockerContext -Name PUID        -Value ([int]568)
#Set-DockerContext -Name PGID        -Value ([int]568)

$Script:Context += ("./tentants/$($Script:Context.General.Tenant).json" | ConvertFrom-Json -AsHashTable)

#if ($Script:Context.General.Tenant -eq "ast") {
#    Set-DockerContext -Name Domain               -Value "ast-ingenieria.com"
#    Set-DockerContext -Name SmtpHostname         -Value "smtp.ast-ingenieria.com"
#    Set-DockerContext -Name SmtpHostPort         -Value "587"
#    Set-DockerContext -Name SmtpUserName         -Value "soporte@ast-ingenieria.com"
#    Set-DockerContext -Name SmtpUserPass         -Value (ConvertTo-SecureString -String "2908cc6d-93cc-4ca2-997f-e668edfa890d" -AsPlainText)
#    Set-DockerContext -Name SmtpProviderHostname -Value "smtp.gmail.com"
#    Set-DockerContext -Name SmtpProviderPort     -Value "465"
#    Set-DockerContext -Name SmtpProviderUserName -Value "soporte@ast-ingenieria.com"
#    Set-DockerContext -Name SmtpProviderUserPass -Value (ConvertTo-SecureString -String "ijac opkc encu oobu" -AsPlainText)
#}
#elseif () {
#    Set-DockerContext -Name Domain               -Value "ast-ingenieria.com"
#    Set-DockerContext -Name SmtpHostname         -Value ""
#    Set-DockerContext -Name SmtpPort             -Value "587"
#    Set-DockerContext -Name SmtpUserName         -Value ""
#    Set-DockerContext -Name SmtpUserPass         -Value ""
#    Set-DockerContext -Name SmtpProviderHostname -Value "smtp.gmail.com"
#    Set-DockerContext -Name SmtpProviderPort     -Value "465"
#    Set-DockerContext -Name SmtpProviderUserName -Value ""
#    Set-DockerContext -Name SmtpProviderUserPass -Value ""
#}

$Script:Context
return
Write-Information -Message "Loaded script '$PSCommandPath'."
