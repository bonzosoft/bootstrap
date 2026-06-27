#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    $singleton = ([IO.FileInfo]$PSCommandPath).BaseName.Replace(".","_").ToUpper()
    if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
        return
    }
    else {
        New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
    }
    Write-Information -MessageData "Loading script '$PSCommandPath'."


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
    [IO.DirectoryInfo]$gitConfigDir = Join-Path -Path $workingDir -ChildPath @(".config", "git")
    [IO.FileInfo]$dockerConfigFile  = Join-Path -Path $workingDir -ChildPath @(".config", "docker.json")
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
    $Script:Context = Get-DockerContext
}

process {

}

end {
    Write-Information -MessageData "Loaded script '$PSCommandPath'."
}
