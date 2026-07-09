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


    # Script settings ==========================================================
    Write-Information -MessageData "Configuring environment."

    [string]$Script:errorMessage = @()
    [IO.DirectoryInfo]$baseDir = ([IO.FileInfo]$PSCommandPath).Directory.Parent
    [IO.DirectoryInfo]$ghConfigDir = Join-Path -Path $baseDir -ChildPath @(".config", "gh")
    [IO.FileInfo]$gitConfigFile = Join-Path -Path $basedir -ChildPath @(".config", "git", ".gitconfig")
    # git: general
    [string]$Script:gitProtocol = "https"
    [string]$Script:gitProvider = "github.com"
    [string]$Script:gitNamespace = "bonzosoft"
    # git: common
    [string]$Script:gitCommonRepository = "common"
    [string]$Script:gitCommonBranch = "main"
    [IO.DirectoryInfo]$Script:commonRepositoryDir = Join-Path -Path $baseDir -ChildPath @($gitCommonRepository)
    # environment variables
    $Env:GH_PROMPT_DISABLED = 1
    $Env:GIT_TERMINAL_PROMPT = 0
    #$Env:GH_TOKEN =
    $Env:GH_CONFIG_DIR = $ghConfigDir
    $Env:GIT_CONFIG_GLOBAL = $gitConfigFile
    

    #Region functions ==========================================================
    function Write-Header($Configuration) {
        Clear-Host
        Write-Host ""
        Write-Host "############################################"
        Write-Host "###           BOOTSTRAP SCRIPT           ###"
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
    #$null = git config --global credential.helper '!gh auth git-credential' 2> variable:errorMessage
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
    
    # remove previous version
    if (Test-Path -Path $commonDir) {
        Write-Information -MessageData "Removing previous version."
        Remove-Item -Path $commonDir -Recurse -Force | Out-Null
    }
    
    # get new version
    Write-Information -MessageData "Cloning repository ${gitNamespace}/${commonRepository} to $commonDir."
    $null = git clone --branch $commonBranch --single-branch "${gitProtocol}://${gitProvider}/${gitNamespace}/${commonRepository}.git" 2> variable:errorMessage
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
    
    Push-Location -Path (Join-Path -Path $PWD -ChildPath @($commonRepository))
    . (Join-Path -Path $commonDir -ChildPath @("common.ps1"))
    Pop-Location


    [IO.DirectoryInfo]$ghDefaultDir = Join-Path -Path $HOME -ChildPath @(".config", "gh")
    foreach ($file in @("hosts.yml", "config.yml")) {
        Move-Item -Path (Join-Path -Path $ghDefaultDir -ChildPath @($file)) -Destination (Join-Path -Path $context.GHConfigDir) -Force
        Remove-item -Path -$ghDefaultDir -Recurse -Force
    }
        
    # create links
    foreach ($item in @("install", "cmd")) {
        Write-Information -MessageData "Adding link '${item}'."
        $source = Join-Path -Path $context.CommonDir -ChildPath @("${item}.sh")
        $target = Join-Path -Path $context.BaseDir.Parent -ChildPath @($item)
        # create link
        $null = ln -snf $source $target  2> variable:errorMessage
        if ($LASTEXITCODE) {
            Write-Error -Message $errorMessage
        }
        # add +x to link
        $null = chmod +x $target 2> variable:errorMessage
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
