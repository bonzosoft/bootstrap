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
        -Path      $PWD `
        -ChildPath @(".config", "config.json")

[Hashtable]$configData = @{
    Git = @{
        Token = ""
    }
    Vault = @{
        Client = @{
            Id     = ""
            Secret = ""
        }
    }
}

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


Clear-Host


[Uri]$assetUri = $null
[Version]$assetVersion = $null

Write-Information -MessageData "Fetching release information from $($bootstrapRepositorySplat.Name)"
$assetUri, $assetVersion =
    Invoke-RestMethod -Uri "https://api.github.com/repos/$($bootstrapRepositorySplat.Organization)/$($bootstrapRepositorySplat.Name)/releases/latest" |
        ForEach-Object -Process {
            # uri
            Write-Output -InputObject (
                $PSItem | 
                Select-Object -ExpandProperty "assets" |
                Where-Object -Property "name" -Like "bootstrap-v*.zip" |
                Select-Object -ExpandProperty browser_download_url -First 1)
            # version
            Write-Output -InputObject (
                $PSItem |
                Select-Object -ExpandProperty name -First 1)
        }


[IO.FileInfo]$assetTempFile = New-TemporaryFile

Write-Information -MessageData "Fetching asset v$assetVersion."
Invoke-WebRequest -Uri $assetUri -OutFile $assetTempFile


[IO.DirectoryInfo]$modulesTempDirectory = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath @([IO.Path]::GetRandomFileName(), "modules")

Write-Information -MessageData "Extracting asset to '$modulesTempDirectory'."
Expand-Archive -Path $assetTempFile -DestinationPath $modulesTempDirectory.Parent -Force


Write-Information -MessageData "Importing asset."
Import-Module -Name (Get-ChildItem -Path $modulesTempDirectory -Directory).FullName


if (Test-Path -Path $configFile) {
    Get-Content -Path $configFile | 
        ConvertFrom-Json -Depth 9 -AsHashtable | 
        ForEach-Object -Process {
            $PSItem.GetEnumerator() | ForEach-Object {
                $configData[$PSItem.Key] = $PSItem.Value
            }
        }
}

$vaultSplat.Credential = $null
if (-not [string]::IsNullOrWhiteSpace($configData.Vault.Client.Secret)) {
    :doWhile do {
        switch (Read-Host -Prompt "Local credentials for Vault already exist. Replace them? [Y]es / [N]o") {
            "y" {
                break doWhile
            }
            "n" {
                $vaultSplat.Credential = [PSCredential]::new($configData.Vault.Client.Id, ($configData.Vault.Client.Secret | ConvertTo-SecureString -AsPlainText))
                break doWhile
            }
        }
    }
    while ($true)
}

if ($null -eq $vaultSplat.Credential) {
    $vaultSplat.Credential = (Get-Credential)
}


[PSCustomObject]$vault = $null
"Creating vault object." | Write-Log
$vault = New-Vault @vaultSplat
Write-Log -Success


"Connecting to vault." | Write-Log
Connect-Vault -Vault $vault -ErrorAction 'Stop'
Write-Log -Success


"Fetching repository token from vault." | Write-Log
$commonRepositorySplat.Token = Get-VaultSecret -Vault $vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/" | ConvertTo-SecureString -AsPlainText -ErrorAction 'Stop'
Write-Log -Success


[PSCustomObject]$repository = $null
"Creating repository object." | Write-Log
$repository = New-GitRepository @commonRepositorySplat
Write-Log -Success


"Connecting to repository '$($repository.Name)'." | Write-Log
Connect-GitRepository -Repository $repository -ErrorAction 'Stop'
Write-Log -Success


"Fetching repository '$($repository.Name)'." | Write-Log
Import-GitRepository -Repository $repository
Write-Log -Success


[IO.FileInfo]$source = $null
[IO.FileInfo]$target = $null
foreach ($item in @("pwsh")) {
    "Creating link for '${item}'." | Write-Log

    $source = Join-Path -Path $PWD -ChildPath @($($repository.Name), "${item}.sh")
    $target = Join-Path -Path $PWD -ChildPath @($item)

    $splat = @{
        Path     = $target
        Value    = $source
        ItemType = 'SymbolicLink'
        Force    = $true
    }
    New-Item @splat | Out-Null
    <#
    ## equivalent to native command: ln -snf $source.FulName $target.FullName
    $params = @(
        "--symbolic"
        "--no-deference"
        "--force"
        $source.FullName
        $target.FullName
    )
    $stdStream = ln @params 2> Variable:errStream
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message ($errStream -join [Environment]::NewLine)
    }
    #>
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


"Saving token to '$configFile'." | Write-Log
if (Test-Path -Path $configFile.Directory -PathType 'Any') {
    if (-not (Test-Path -Path $configFile.Directory -PathType 'Container')) {
        Remove-Item -Path $configFile.Directory -Force
    }
}

if (-not (Test-Path -Path $configFile.Directory -PathType 'Container')) {
    New-Item -Path $configFile.Directory -ItemType 'Directory' -Force | Out-Null
}

$configData.Git.Token           = $repository.Token | ConvertFrom-SecureString -AsPlainText
$configData.Vault.Client.Id     = $vault.Credential.GetNetworkCredential().UserName
$configData.Vault.Client.Secret = $vault.Credential.GetNetworkCredential().Password

$configData | ConvertTo-Json -Depth 9 | Set-Content -Path $configFile
Write-Log -Success


#. (Join-Path -Path $PWD -ChildPath @($commonRepositorySplat.Name, "install.ps1"))
################################################################################## continuar en install.ps1 a partir de aqui


"Press any key to continue..." | Write-Log
Read-Host | Out-Null
