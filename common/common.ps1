#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param(

)

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    New-Variable -Name "singleton" -Scope Global -Value ("__INCLUDED_$(([IO.FileInfo]$PSCommandPath).Name.Replace(".","_").ToUpper())__")
    if (Get-Variable -Name $singleton -Scope Global -ErrorAction SilentlyContinue) {
        Write-Information -MessageData "Script '$PSCommandPath' already loaded. Skipping."
        return
    }
    else {
        Write-Information -MessageData "Loading script '$PSCommandPath'."
        New-Variable -Name $singleton -Scope Global -Value $true
    }
    Remove-Variable -Name "singleton"
}

process {
    # ==========================================================================
    # GENERAL CONFIGURATION
    # ==========================================================================
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $VerbosePreference = 'Continue'


    # ==========================================================================
    # MODULES
    # ==========================================================================
    [string[]]$modules = @(
        "pwsh-Docker"
        "pwsh-Git"
    )
    New-Variable -Name "backupVerbosePreference" -Value $VerbosePreference
    $VerbosePreference = 'SilentlyContinue'
    foreach ($module in $modules) {
        Write-Information -MessageData "Loading module '$module'."
        Import-Module -Name (Join-Path -Path ([IO.FileInfo]$PSCommandPath).Directory -ChildPath @("modules", $module))
    }
    $VerbosePreference = $backupVerbosePreference
    Remove-Variable -Name "backupVerbosePreference"


    # ==========================================================================
    # ENVIRONMENT VARIABLES
    # ==========================================================================
    $Env:GH_CONFIG_DIR = Join-Path -Path $([IO.FileInfo]$PSCommandPath).Directory.Parent -ChildPath @(".config", "github-cli")
    $Env:GH_PROMPT_DISABLED = 1
    $Env:GIT_TERMINAL_PROMPT = 0

    # ==========================================================================
    # VARIABLES
    # ==========================================================================
    Write-Information -MessageData "Configuring environment."
    # text user interface
    [string]$Script:scriptVersion = "00.01.16"
    [string[]]$Script:errorMessage = @()
    # paths
    [IO.DirectoryInfo]$Script:currentDirectory = $PWD.Path
    [IO.FileInfo]$Script:dockerConfigFile = Join-Path -Path $([IO.FileInfo]$PSCommandPath).Directory.Parent -ChildPath @(".config", "docker.json")
    # git: general
    [string]$Script:gitProtocol = "https"
    [string]$Script:gitProvider = "github.com"
    [string]$Script:gitNamespace = "bonzosoft"
    # git: common
    [string]$Script:commonRepository = "common"
    [string]$Script:commonBranch = "main"
    [IO.DirectoryInfo]$Script:commonDir = Join-Path -Path $currentDirectory -ChildPath @($commonRepository)
    # git: core
    [string]$Script:coreRepository = "komodo-core"
    [string]$Script:coreBranch = "main"
    [IO.DirectoryInfo]$Script:coreDir = Join-Path -Path $currentDirectory -ChildPath @($coreRepository)
    # git: periphery
    [string]$Script:peripheryRepository = "komodo-periphery"
    [string]$Script:peripheryBranch = "main"
    [IO.DirectoryInfo]$Script:peripheryDir = Join-Path -Path $currentDirectory -ChildPath @($peripheryRepository)
    # context
    [hashtable]$Script:context = Get-DockerContext -Path $dockerConfigFile
}

end {
    Write-Information -MessageData "Completed script '$PSCommandPath'."
}
