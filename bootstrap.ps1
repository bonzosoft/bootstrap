[CmdletBinding()]
[OutputType([void])]
param()

[IO.FIleInfo]$configFile = Join-Path -Path $PWD -ChildPath @(".config", "config.json")

[hashtable]$commonRepositorySplat           = @{}
[uri]$commonRepositorySplat.Domain          = "https://github.com"
[string]$commonRepositorySplat.Organization = "bonzosoft"
[string]$commonRepositorySplat.Name         = "common"
[string]$commonRepositorySplat.Branch       = "bw"

# apt update
$splat = @{
    FilePath     = "apt"
    ArgumentList = @(
        "update"
    )
    Environment  = @{}
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat

# apt install gh --yes
$splat = @{
    FilePath = "apt"
    ArgumentList = @(
        "install"
        "gh"
        "--yes"
    )
    Environment  = @{}
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat

# gh config set prompt disabled
$splat = @{
    FilePath     = "gh"
    ArgumentList = @(
        "config"
        "set"
        "prompt", "disabled"
    )
    Environment  = @{}
    Wait         = $true
    NoNewWindow  = $true
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

do {
    if ($configData.Git.Token) {
        $splat = @{
            FilePath = "gh"
            ArgumentList = @(
                "auth"
                "status"
            )
            Environment = @{
                GH_TOKEN = $configData.Git.Token
            }
            Wait         = $true
            NoNewWindow  = $true
            ErrorAction  = 'Stop'
        }
        Start-Process @splat

        [bool]$successLogin = -not($LASTEXITCODE)
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
            Wait         = $false
            NoNewWindow  = $true
            ErrorAction  = 'Stop'
        }
        Start-Process @splat
    }
}
while (-not $successLogin)

if (Test-Path -Path "common") {
    Remove-Item -Path "common" -Recurse -Force
}

$splat = @{
    FilePath     = "gh"
    ArgumentList = @(
        "repo"
        "clone"
        "$($commonRepositorySplat.Organization)/$($commonRepositorySplat.Name)"
        "--branch", $commonRepositorySplat.Branch
        "--single-branch"
        "--depth", 1
    )
    Environment = @{
        GH_TOKEN = $configData.Git.Token
    }
    Wait         = $true
    NoNewWindow  = $true
    ErrorAction  = 'Stop'
}
Start-Process @splat
