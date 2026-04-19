Write-Host "Loading $PSCommandPath"


## COMMON SCRIPT ###############################################################

## UPDATE SUBMODULES
if ($IsLinux) {
    git submodule update --init --recursive --depth 1
}

## SET .env FILE ACCORDING TO REALM
[IO.FileInfo]$realmDotEnvFile = Join-Path -Path $Script:WORKINGDIR -ChildPath "./.env.$Realm"
if (Test-Path -Path $realmDotEnvFile) {
    New-Item -Path $workingDotEnvFile -ItemType SymbolicLink -Value $realmDotEnvFile -Force | Out-Null
}

## SET COMMON .env VARIABLES
Set-DockerVariable -Path $workingDotEnvFile -Name DATADIR    -Value $Script:DataDir    -Force
Set-DockerVariable -Path $workingDotEnvFile -Name INCLUDEDIR -Value $Script:IncludeDir -Force
Set-DockerVariable -Path $workingDotEnvFile -Name SECRETSDIR -Value $Script:SecretsDir -Force

Write-Host "Finishing $PSCommandPath"