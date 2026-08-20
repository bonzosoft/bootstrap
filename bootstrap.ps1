#-not /usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()


Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
#$PSNativeCommandUseErrorActionPreference = 'Continue'


#Region ── Constants ───────────────────────────────────────────────────────────
[IO.FileInfo]$thisScript = $PSCommandPath

[IO.FileInfo]$configFile = 
    Join-Path `
        -Path $PWD `
        -ChildPath @(".config", "config.json")

[IO.DirectoryInfo]$modulesDirectory = 
    Join-Path `
        -Path ([System.IO.Path]::GetTempPath()) `
        -ChildPath @([System.IO.Path]::GetRandomFileName(), "modules")

[Hashtable]$vaultSplat = @{
    Domain       = "https://eu.infisical.com"
    Organization = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
    Project      = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
    Environment  = "dev"
}

[Hashtable]$commonRepositorySplat = @{
    Domain       = "https://github.com"
    Organization = "bonzosoft"
    Name         = "common"
    Branch       = "bw"
}

[Hashtable]$bootstrapRepositorySplat = @{
    Domain       = "https://github.com"
    Organization = "bonzosoft"
    Name         = "bootstrap"
    Branch       = "main"
}

[Hashtable]$splat = @{}
[string[]]$stdStream = @()
[string[]]$errStream = @()
[string[]]$params = @()
#EndRegion ─────────────────────────────────────────────────────────────────────


#Region ── Local functions ─────────────────────────────────────────────────────
function Write-Log {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "Message")]
        [ValidateNotNullOrWhiteSpace()]
        [string[]]$Message,

        [Parameter(Mandatory, ParameterSetName = "Success")]
        [switch]$Success
    )

    process {
        [string]$timestamp = "[" + $(Get-Date -Format "yyyy-MM-dd HH:mm:ss:fffK") + "]" + (" "*2)
        switch ($PSCmdlet.ParameterSetName) {
            "Message" {
                foreach ($item in $Message) {
                    Write-Information -MessageData ($timestamp + $item) -InformationAction 'Continue'

                    continue
                }
            }
            "Success" {
                Write-Information -MessageData ($timestamp + ">> OK") -InformationAction 'Continue'
            }
            default {
                throw "Unknown parameter set name '$PSItem'."
            }
        }
    }
}
#EndRegion ─────────────────────────────────────────────────────────────────────


Clear-Host


"Getting asset metadata from repository $($bootstrapRepositorySplat.Name)" | Write-Log
[Uri]$assetUri, [Version]$assetVersion = 
    Invoke-RestMethod -Uri "https://api.github.com/repos/$($bootstrapRepositorySplat.Organization)/$($bootstrapRepositorySplat.Name)/releases/latest" |
        ForEach-Object -Process {
            Write-Output -InputObject (
                $PSItem | 
                Select-Object -ExpandProperty "assets" |
                Where-Object -Property "name" -Like "bootstrap-v*.zip" |
                Select-Object -ExpandProperty browser_download_url -First 1)
            Write-Output -InputObject (
                $PSItem |
                Select-Object -ExpandProperty name -First 1)
        }
Write-Log -Success


"Downloading asset version: v$assetVersion from repository." | Write-Log
[IO.FileInfo]$assetTempFile = New-TemporaryFile
Invoke-WebRequest -Uri $assetUri -OutFile $assetTempFile
Write-Log -Success


"Extracting assets to '$modulesDirectory'." | Write-Log
Expand-Archive -Path $assetTempFile -DestinationPath $modulesDirectory.Parent -Force
Write-Log -Success


"Importing assets." | Write-Log
Import-Module -Name (Get-ChildItem -Path $modulesDirectory -Directory).FullName
Write-Log -Success


"Getting local data from '$configFile'." | Write-Log
[Hashtable]$configData = Get-Content -Path $configFile -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 9 -AsHashTable
if (($null -ne $configData) -and ($configData.Keys -contains "Git")) {
    if ($configData.Git.Keys -contains "Token") {
        $commonRepositorySplat.Token = $configData.Git.Token | ConvertTo-SecureString -AsPlainText
    }
}
if (($null -ne $configData) -and ($configData.Keys -contains "Vault")) {
    if ($configData.Vault.Keys -contains "ClientId" -and $configData.Vault.Keys -contains "ClientSecret") {

        $vaultSplat.Credential = [PSCredential]::new($configData.Vault.ClientId, ($configData.Vault.ClientSecret | ConvertTo-SecureString -AsPlainText))
    }
}
Write-Log -Success


#Connect-GitRepository -Repository $repository -ErrorAction 'SilentlyContinue'
"Creating Vault object." | Write-Log
$vault = New-Vault @vaultSplat
Write-Log -Success

$vault.Credential = (Get-Credential)

"Connecting vault." | Write-Log
Connect-Vault -Vault $vault -ErrorAction 'Stop'
Write-Log -Success


"Fetching token from vault." | Write-Log
$repository.Token = Get-VaultSecret -Vault $vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/" | ConvertTo-SecureString -AsPlainText -ErrorAction 'Stop'
Write-Log -Success

"Connecting repository." | Write-Log
Connect-GitRepository -Repository $repository -ErrorAction 'Stop'
Write-Log -Success


"Creating repository object." | Write-Log
$repository = New-GitRepository @commonRepositorySplat
Write-Log -Success

"Getting repository '$($repository.Name)'." | Write-Log
Import-GitRepository -Repository $repository
Write-Log -Success


"Storing token." | Write-Log
if (Test-Path -Path -Path $configFile.Directory -PathType 'Any') {
    Remove-Item -Path $configFile.Directory -Force
}
if (-not (Test-Path -Path $configFile.Directory -PathType 'Container')) {
    New-Item -Path $configFile.Directory -ItemType 'Directory' -Force | Out-Null
}
@{
    "Git" = @{
        "Token" = ($repository.Token | ConvertFrom-SecureString -AsPlainText)
    }
} | ConvertTo-Json -Depth 9 | Set-Content -Path $configFile
Write-Log -Success


foreach ($item in @("pwsh")) {
    [IO.FileInfo]$source =
        Join-Path `
            -Path $PWD `
            -ChildPath @("common", "${item}.sh") #Join-Path -Path $repository.Path -ChildPath @("${item}.sh")
    [IO.FileInfo]$target = 
        Join-Path `
            -Path $PWD `
            -ChildPath @($item)

    "Creating link for '${item}'." | Write-Log
    $splat = @{
        Path     = $target
        Value    = $source
        ItemType = 'SymbolicLink'
        Force    = $true
    }
    New-Item @splat | Out-Null # sames as native command: ln -snf $source.FulName $target.FullName
    Write-Log -Success


    "Setting '${item}' as executable." | Write-Log
    $params = @(
        "+x"
        $source.FullName
    )
    $stdStream = chmod @params 2> variable:errStream
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message ($errStream -join [Environment]::NewLine)
    }
    Write-Log -Success
}

#. (Join-Path -Path $PWD -ChildPath @($commonRepositorySplat.Name, "install.ps1"))
################################################################################## continuar en install.ps1 a partir de aqui


"" | Write-Log
"Press any key to continue..." | Write-Log
Read-Host | Out-Null



