#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]
param()

begin {
    # Command line setup =======================================================
    Set-StrictMode -Version 'Latest'
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'

    # Script start =============================================================
    [IO.FileInfo]$thisScript = $PSCommandPath
    
    [IO.FIleInfo]$configFile = Join-Path -Path $PWD -ChildPath @(".config", "config.json")

    [hashtable]$commonRepositorySplat             = @{}
    [uri]$commonRepositorySplat.Domain            = "https://github.com"
    [string]$commonRepositorySplat.Organization   = "bonzosoft"
    [string]$commonRepositorySplat.Name           = "common"
    [string]$commonRepositorySplat.Branch         = "bw"
    [IO.DirectoryInfo]$commonRepositorySplat.Path = Join-Path -Path $PWD -ChildPath @($commonRepositorySplat.Name)
}

process {
    # apt update
    $splat = @{
        FilePath     = "apt"
        ArgumentList = @("update")
        Environment  = @{}
        NoNewWindow  = $true
        Wait         = $true
        ErrorAction  = 'Stop'
    }
    Start-Process @splat
    
    # apt install gh --yes
    $splat = @{
        FilePath = "apt"
        ArgumentList = @("install", "gh", "--yes")
        Environment  = @{}
        NoNewWindow  = $true
        Wait         = $true
        ErrorAction  = 'Stop'
    }
    Start-Process @splat
    
    # gh config set prompt disabled
    $splat = @{
        FilePath     = "gh"
        ArgumentList = @("config", "set", "prompt", "disabled")
        Environment  = @{}
        NoNewWindow  = $true
        Wait         = $true
        ErrorAction  = 'Stop'
    }
    Start-Process @splat
    
    [hashtable]$configData = Get-Content -Path $configFile -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 9 -AsHashtable -ErrorAction 'SilentlyContinue'
    if ($null -eq $configData) {
        [hashtable]$configData = @{}
    }
    if (-not($configData.Keys -contains "Git")) {
        [hashtable]$configData.Git = @{}
    }
    if (-not($configData.Git.Keys -contains "Token")) {
        [string]$configData.Git.Token = ""
    }
    
    [bool]$successLogin = $false
    do {
        if ($configData.Git.Token) {
            $splat = @{
                FilePath = "gh"
                ArgumentList = @("auth", "status")
                Environment = @{GH_TOKEN = $configData.Git.Token}
                NoNewWindow  = $true
                Wait         = $true
                ErrorAction  = 'Stop'
            }
            Start-Process @splat
    
            $successLogin = -not $LASTEXITCODE
        }
        else {
            $splat = @{
                FilePath = "gh"
                ArgumentList = @(
                    "auth"
                    "login"
                    "--git-protocol", $commonRepositorySplat.Domain.Scheme
                    "--hostname", $commonRepositorySplat.Domain.Host
                )
                Environment  = @{}
                NoNewWindow  = $true
                Wait         = $false
                ErrorAction  = 'Stop'
            }
            Start-Process @splat
        }
    }
    while (-not $successLogin)
    
    if (Test-Path -Path $commonRepositorySplat.Path) {
        Remove-Item -Path $commonRepositorySplat.Path -Recurse -Force
    }
    
    $splat = @{
        FilePath     = "gh"
        ArgumentList = @(
            "repo"
            "clone"
           ($commonRepositorySplat.Organization) + "/" + $($commonRepositorySplat.Name)
            $commonRepositorySplat.Path
            "--"
            "--branch", $commonRepositorySplat.Branch
            "--single-branch"
            "--depth", 1
        )
        Environment = @{GH_TOKEN = $configData.Git.Token}
        NoNewWindow  = $true
        Wait         = $true
        ErrorAction  = 'Stop'
    }
    Start-Process @splat  
}

end {
    # Script end ===============================================================
    Write-Information -MessageData "Completed script '$($Script:thisScript.Pop())'."
}

clean {
    # nop
}
