#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param(

)

begin {
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
        # nop
        # nop
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
    [string]$Script:scriptVersion = "00.01.30"
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
    #[string]$Script:coreRepository = "komodo-core"
    #[string]$Script:coreBranch = "main"
    #[IO.DirectoryInfo]$Script:coreDir = Join-Path -Path $currentDirectory -ChildPath @($coreRepository)
    # git: periphery
    #[string]$Script:peripheryRepository = "komodo-periphery"
    #[string]$Script:peripheryBranch = "main"
    #[IO.DirectoryInfo]$Script:peripheryDir = Join-Path -Path $currentDirectory -ChildPath @($peripheryRepository)
    # context
    #[hashtable]$Script:context = Get-DockerContext -Path $dockerConfigFile


    # ==========================================================================
    # FUNCTIONS
    # ==========================================================================
    function Write-Header($Configuration) {
        Clear-Host
        Write-Host ""
        Write-Host "############################################"
        Write-Host "###            INSTALL SCRIPT            ###"
        Write-Host "###   --------------------------------   ###"
        Write-Host "###         [Version:  ${scriptVersion}]         ###"
        Write-Host "############################################"
        Write-Host ""
    }
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
