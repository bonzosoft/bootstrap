#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    [string]$Script:scriptVersion="0.1.34"


    # Command line setup =======================================================
    Set-StrictMode -Version 'Latest'
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'


    # Script start =============================================================
    Write-Information -MessageData "Loading script '$PSCommandPath'."


    # Script settings ==============================================================
    Write-Information -MessageData "Configuring environment."
        
    [string[]]$Script:errorMessage = @()
    # paths
    $workingDir = ([IO.FileInfo]$PSCommandPath).Directory
    $context.RootDir          = [IO.DirectoryInfo]$workingDir.Parent
    $context.CommonConfigDir  = [IO.DirectoryInfo](Join-Path -Path $context.RootDir -ChildPath @(".config"))
    $context.GHConfigDir      = [IO.DirectoryInfo](Join-Path -Path $context.CommonConfigDir -ChildPath @("gh-cli"))
    $context.CommonConfigFile = [IO.FileInfo](Join-Path -Path $context.CommonConfigDir - ChildPath @("deploy.json"))
    # environment variables
    $Env:GH_CONFIG_DIR = $context.GHConfigDir
    $Env:GH_PROMPT_DISABLED = 1
    $Env:GIT_TERMINAL_PROMPT = 0
    [IO.DirectoryInfo]$Script:StacksDir = ([IO.FileInfo]$PSCommandPath).Directory # /mnt/tank0/apps/stacks
    [IO.DirectoryInfo]$Script:Deploy = Join-Path -Path $appsDir -ChildPath @(".config")
    [IO.FileInfo]$Script:configFile = Join-Path -Path $configDir -ChildPath @("deploy.json")
    # git: general
    [string]$Script:gitProtocol = "https"
    [string]$Script:gitProvider = "github.com"
    [string]$Script:gitNamespace = "bonzosoft"
    # git: common
    [string]$Script:commonRepository = "common"
    [string]$Script:commonBranch = "main"
    [IO.DirectoryInfo]$Script:commonDir = Join-Path -Path $PWD -ChildPath @($commonRepository)
    
    $Env:GH_CONFIG_DIR = Join-Path -Path $configDir -ChildPath @("github-cli")
    $Env:GH_PROMPT_DISABLED = 1
    $Env:GIT_TERMINAL_PROMPT = 0


    #Region functions
    function Write-Header($Configuration) {
        Clear-Host
        Write-Host ""
        Write-Host "############################################"
        Write-Host "###            INSTALL SCRIPT            ###"
        Write-Host "###   --------------------------------   ###"
        Write-Host "###        [Version:$(" "*(12-$scriptVersion.Length))$scriptVersion]        ###"
        Write-Host "############################################"
        Write-Host ""
    }
    #EndRegion
}

process {
    trap {
        Get-Error -InputObject $PSItem | Format-List * -Force
        Read-Host | Out-Null
    }
    
    # ==========================================================================
    # SCRIPT
    # ==========================================================================
    Clear-Host
    Write-Header
    
    # check session for Github CLI 
    Write-Information -MessageData "Checking session for ${gitProvider}."
    $null = gh auth status *> $null
    if ($LASTEXITCODE) {
        gh auth login --git-protocol $gitProtocol --hostname $gitProvider --web
    }
    
    # propagate session to git
    Write-Information -MessageData "Asserting session for Git."
    $null = gh auth setup-git 2> variable:errorMessage
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
    
    # remove previous version
    if (Test-Path -Path $commonDir) {
        Write-Information -MessageData "Removing previous version."
        Remove-Item -Path $commonDir -Recurse -Force | Out-Null
    }
    
    # get new version
    Write-Information -MessageData "Cloning repository ${gitNamespace}/${commonRepository}."
    $null = git clone --branch $commonBranch --single-branch "${gitProtocol}://${gitProvider}/${gitNamespace}/${commonRepository}.git" 2> variable:errorMessage
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
    
    # create links
    foreach ($item in @("install", "cmd")) {
        Write-Information -MessageData "Adding link '${item}'."
        $null = ln -snf (Join-Path -Path $commonDir -ChildPath @("${item}.sh")) (Join-Path -Path $workingDir -ChildPath @($item)) 2> variable:errorMessage
        if ($LASTEXITCODE) {
            Write-Error -Message $errorMessage
        }
        $null = chmod +x (Join-Path -Path $workingDir -ChildPath @($item)) 2> variable:errorMessage
        if ($LASTEXITCODE) {
            Write-Error -Message $errorMessage
        }
    }
}

end {
    Write-Information -MessageData ""
    Write-Information -MessageData "Press any key to continue..."
    Read-Host | Out-Null
}
