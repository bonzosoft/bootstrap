#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    [string]$Script:scriptVersion="0.1.36"


    # Command line setup =======================================================
    Set-StrictMode -Version 'Latest'
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'


    # Script start =============================================================
    Write-Information -MessageData "Loading script '$PSCommandPath'."


    # Script settings ==========================================================
    Write-Information -MessageData "Configuring environment."

    [string]$Script:errorMessage = @()
    # git: paths
    [IO.DirectoryInfo]$gitBaseDir = ([IO.FileInfo]$PSCommandPath).Directory.Parent
    [IO.DirectoryInfo]$ghConfigDir = Join-Path -Path $gitBaseDir -ChildPath @(".config", "gh")
    $Env:GH_CONFIG_DIR = $ghConfigDir
    $Env:GH_PROMPT_DISABLED = 1
    [IO.FileInfo]$gitConfigFile = Join-Path -Path $gitBaseDir -ChildPath @(".config", "git", "config")
    $Env:GIT_CONFIG_GLOBAL = $gitConfigFile
    $Env:GIT_TERMINAL_PROMPT = 0
    # git: general
    [string]$Script:gitProtocol = "https"
    [string]$Script:gitProvider = "github.com"
    [string]$Script:gitNamespace = "bonzosoft"
    # git: common
    [string]$Script:gitCommonRepository = "common"
    [string]$Script:gitCommonBranch = "main"
    [IO.DirectoryInfo]$Script:gitCommonDir = Join-Path -Path $gitBaseDir -ChildPath @($gitCommonRepository)
    ## git: komodo core
    #[string]$Script:gitCoreRepository = "komodo-core"
    #[string]$Script:gitCoreBranch = "main"
    #[IO.DirectoryInfo]$Script:gitCoreDir = Join-Path -Path $gitBaseDir -ChildPath @($gitCoreRepository)
    ## git: komodo periphery
    #[string]$Script:gitPeripheryRepository = "komodo-periphery"
    #[string]$Script:gitPeripheryBranch = "main"
    #[IO.DirectoryInfo]$Script:gitPeripheryDir = Join-Path -Path $gitBaseDir -ChildPath @($gitPeripheryRepository)


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
    if (-not (Test-Path -Path $gitConfigFile)) {
        New-Item -Path $gitConfigFile -ItemType File -Force | Out-Null
    }
    $null = gh auth setup-git 2> variable:errorMessage #$null = git config --global credential.helper '!gh auth git-credential' 2> variable:errorMessage
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
    
    # remove previous version
    if (Test-Path -Path $gitCommonDir) {
        Write-Information -MessageData "Removing previous version."
        Remove-Item -Path $gitCommonDir -Recurse -Force | Out-Null
    }
    
    # get new version
    Write-Information -MessageData "Cloning repository ${gitNamespace}/${gitCommonRepository} to $gitCommonDir."
    $null = git clone --branch $gitCommonBranch --single-branch "${gitProtocol}://${gitProvider}/${gitNamespace}/${gitCommonRepository}.git" 2> variable:errorMessage
    if ($LASTEXITCODE) {
        Write-Error -Message $errorMessage
    }
            
    # create links
    foreach ($item in @("install", "cmd")) {
        Write-Information -MessageData "Adding link '${item}'."
        
        $source = Join-Path -Path $gitCommonDir -ChildPath @("${item}.sh")
        $target = Join-Path -Path $gitBaseDir -ChildPath @($item)
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
    Write-Information -MessageData ""
    switch (Read-Host -Prompt "Press 'y' to continue with the install or any other key to finish") {
        "y" {
            write-Host $PWD
            pwsh -File (Join-Path -Path $gitCommonRepository -ChildPath @("./install.ps1"))
        }
        default {
            exit 0
        }
    }
}
