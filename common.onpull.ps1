#!/usr/bin/env pwsh

### SINGLETON ##################################################################
$singleton = ([IO.FileInfo]$PSCommandPath).BaseName.Replace(".","_").ToUpper()
if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
}
Write-Information -MessageData "Loading script '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


## PULL SUBMODULES #############################################################
if (Test-Path -Path $Script:Context.IncludeDir) {


    [string[]]$errorMessage         = @()
    [IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $PWD -ChildPath @(".config", "git")
    [IO.FileInfo]$dockerConfigFile  = Join-Path -Path $PWD -ChildPath @(".config", "docker.json")
    [string]$gitProtocol            = "https"
    [string]$gitProvider            = "github.com"
    [string]$gitNamespace           = "bonzosoft"
    [string]$commonRepository       = "common"
    [string]$commonBranch           = "main"
    [IO.DirectoryInfo]$commonDir    = Join-Path -Path $PWD -ChildPath @($commonRepository)
    [string]$coreRepository         = "komodo-core"
    [string]$coreBranch             = "main"
    [IO.DirectoryInfo]$coreDir      = Join-Path -Path $PWD -ChildPath @($coreRepository)
    [string]$peripheryRepository    = "komodo-periphery"
    [string]$peripheryBranch        = "main"
    [IO.DirectoryInfo]$peripheryDir = Join-Path -Path $PWD -ChildPath @($peripheryRepository)
    
    [IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $PWD -ChildPath @(".config", "git")
    [IO.FileInfo]$dockerConfigFile  = Join-Path -Path $PWD -ChildPath @(".config", "docker.json")
    [IO.DirectoryInfo]$commonDir    = Join-Path -Path $PWD -ChildPath @($commonRepository)
    [IO.DirectoryInfo]$coreDir      = Join-Path -Path $PWD -ChildPath @($coreRepository)
    [IO.DirectoryInfo]$peripheryDir = Join-Path -Path $PWD -ChildPath @($peripheryRepository)
    
    $env:GH_CONFIG_DIR = $gitConfigDir
    $env:GIT_TERMINAL_PROMPT = 0



    [IO.DirectoryInfo]$configDir  = Join-Path -Path "/mnt/tank0" -ChildPath @("apps", "infra", ".config")
    [IO.FileInfo]$configFile = Join-Path -Path $configDir -ChildPath @("host", "config.json")

    $env:GH_CONFIG_DIR=(Join-Path -Path $configDir -ChildPath @("gh"))
    $env:GIT_TERMINAL_PROMPT = 0


    [string]$gitProvider = "github.com"
    [string]$gitNamespace = "bonzosoft"
    [string]$commonGitRepository = "common"
    [string]$commonGitBranch = "main"
    [string]$coreGitRepository = "komodo-core"
    [string]$coreGitBranch = "main"
    [string]$peripheryGitRepository = "komodo-periphery"
    [string]$peripheryGitBranch = "main"

    Assert-GitProviderSession -Provider $gitProvider
    Write-Information -MessageData "Pulling submodules."
    $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
    if ($LASTEXITCODE) {
        throw ($errorVariable | Out-String)
    }
}


## SET ENV FILE VARIABLES ######################################################
Get-Content -Path $Script:Context.MainDotEnvFile -Encoding utf8 |
ForEach-Object { Expand-DockerVariable -Content $PSItem } | 
Set-Content -Path "$($Script:Context.MainDotEnvFile).tmp" -Encoding utf8
Move-Item -Path "$($Script:Context.MainDotEnvFile).tmp" -Destination $Script:Context.MainDotEnvFile -Force
Write-Verbose -Message ($Script:Context | Out-String)


## GET SERVICES INFORMATION ####################################################
$compose = Get-DockerCompose -Path $Script:Context.MainComposeFile
$volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys -Verbose
$Script:Context += @{
    "Service"= $volumes
}
Write-Verbose -Message ($Script:Context | Out-String)


## LOAD SUBMODULES SCRIPTS #####################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    foreach ($script in (Get-Item -Path (Join-Path -Path $Script:Context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))) {
        Write-Information -MessageData "Loading submodule script '$($script.FullName)'."
        . $script.FullName
    }
}


## SET STORAGE PERMISSION ######################################################
foreach ($service in $Script:Context.Service.Keys) {
    if ($Script:Context.Service.$service.Volume) {
        Write-Information -MessageData "Configuring storage for service $($service)"
        Grant-DockerPermission `
            -Path $Script:Context.Service.$service.Volume `
            -PUID $Script:Context.Service.$service.PUID `
            -PGID $Script:Context.Service.$service.PGID `
            -Permission "0775" `
            -Force
    }
}


Write-Information -MessageData "Loaded script '$PSCommandPath'."
