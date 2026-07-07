#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    [string]$Script:scriptVersion="0.1.35"


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
    [hashtable]$context = [ordered]@{}
    $context.RootDir          = [IO.DirectoryInfo]([IO.FileInfo]$PSCommandPath).Directory
    $context.DeployConfigDir  = [IO.DirectoryInfo](Join-Path -Path $context.RootDir -ChildPath @(".config"))
    $context.DeployConfigFile = [IO.FileInfo](Join-Path -Path $context.DeployConfigDir -ChildPath @("deploy.json"))
    # environment variables
    $Env:GH_CONFIG_DIR = $context.DeployConfigDir
    $Env:GH_PROMPT_DISABLED = 1
    $Env:GIT_TERMINAL_PROMPT = 0
    # git: general
    [string]$Script:gitProtocol = "https"
    [string]$Script:gitProvider = "github.com"
    [string]$Script:gitNamespace = "bonzosoft"
    # git: common
    [string]$Script:commonRepository = "common"
    [string]$Script:commonBranch = "main"
    [IO.DirectoryInfo]$Script:commonDir = Join-Path -Path $PWD -ChildPath @($commonRepository)
    
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
