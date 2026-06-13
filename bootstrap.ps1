#!/usr/bin/env pwsh

$InformationPreference = 'Continue'

[System.IO.DirectoryInfo]$WorkingDir = (Get-Location).Path
[System.IO.DirectoryInfo]$GHConfigDir = Join-Path -Path $WorkingDir -ChildPath "" -AdditionalChildPath @(".config", "gh")
[System.IO.FileInfo]$HostConfigFile = Join-Path -Path $WorkingDir -ChildPath "" -AdditionalChildPath @(".config", "host", "config.json")


Write-Host "workingdir: ${WorkingDir}"
Write-Host "information: $GHConfigDir"
Write-Information "information: $HostConfigFile"