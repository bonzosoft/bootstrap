#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    [IO.FileInfo]$currentScriptInfo = $PSCommandPath
    New-Variable -Name singleton -Value ("__INCLUDED_$($currentScriptInfo.Name.Replace(".","_").ToUpper())__")
    Write-Host "singleton: $singleton"
    if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
        Write-Warning -Message "Script '$PSCommandPath' already loaded. Skipping."
        return
    }
    else {
        Write-Information -MessageData "Loading script '$PSCommandPath'."
        New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
    }
    Remove-Variable -Name singleton


    # ==========================================================================
    # GENERAL CONFIGURATION
    # ==========================================================================
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    $VerbosePreference     = 'Continue'


    # ==========================================================================
    # MODULES
    # ==========================================================================
    [string[]]$modules = @(
        "pwsh-Docker"
        "pwsh-Git"
    )

    New-Variable -Name verboseBackup -Value ([string]$VerbosePreference) 
    $VerbosePreference = 'SilentlyContinue'
    foreach ($module in $modules) {
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath @("modules", $module))
    }
    $VerbosePreference = $verboseBackup
    Remove-Variable -Name verboseBackup


    # ==========================================================================
    # CONSTANTS
    # ==========================================================================
    [string]$scriptVersion          = "00.01.16"
    [string[]]$errorMessage         = @()
    [IO.DirectoryInfo]$workingDir   = $PWD.Path
    [IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $PSScriptRoot -ChildPath @("..", ".config", "github-cli")
    [IO.FileInfo]$dockerConfigFile  = Join-Path -Path $PSScriptRoot -ChildPath @("..", ".config", "docker.json")
    [string]$gitProtocol            = "https"
    [string]$gitProvider            = "github.com"
    [string]$gitNamespace           = "bonzosoft"
    [string]$commonRepository       = "common"
    [string]$commonBranch           = "main"
    [IO.DirectoryInfo]$commonDir    = Join-Path -Path $workingDir -ChildPath @($commonRepository)
    [string]$coreRepository         = "komodo-core"
    [string]$coreBranch             = "main"
    [IO.DirectoryInfo]$coreDir      = Join-Path -Path $workingDir -ChildPath @($coreRepository)
    [string]$peripheryRepository    = "komodo-periphery"
    [string]$peripheryBranch        = "main"
    [IO.DirectoryInfo]$peripheryDir = Join-Path -Path $workingDir -ChildPath @($peripheryRepository)

    $env:GH_CONFIG_DIR = $gitConfigDir
    $env:GIT_TERMINAL_PROMPT = 0


    # ==========================================================================
    # CONTEXT
    # ==========================================================================
    $Script:Context = Get-DockerContext -Path $dockerConfigFile
}

process {

}

end {
    Write-Information -MessageData "Loaded script '$PSCommandPath'."
}
