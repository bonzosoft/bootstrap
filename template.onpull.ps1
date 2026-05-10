#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()


Write-Information -Message "Loading script '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path "../*/common.$(Split-Path -Path $PSCommandPath -Leaf)")


### VARIABLES ##################################################################
Set-DockerVariable -Name "WORKER_CONNECT_AS" -Value $Script:Context.Hostname


### SECRETS ####################################################################
if (-not (Test-DockerSubmodule)) {
    Set-DockerSecret -Name "db-name"     -Value "mongodb"
    Set-DockerSecret -Name "db-username" -Value "mongodb"
    Set-DockerSecret -Name "db-userpass" -Password
}


### CONFIGURATION FILES ########################################################
[IO.FileInfo[]]@(
) |
Set-DockerConfigFile -Service "db" -Link -Force |
Grant-DockerPermission -PUID $Script:Context.PUID -PGID $Script:Context.PGID -Permission "0755"


Write-Host "Finishing '$PSCommandPath'."
