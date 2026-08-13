#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    Clear-Host

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'

   #[string[]]$stdStream = @()
    [string[]]$errStream = @()
    [string[]]$params = @()
    [Hashtable]$splat = @{}
    [object]$output = $null
    [Version]$scriptVersion = "0.0.3"

    #Region Local functions
    function Get-Timestamp {
        Write-Output -InputObject ("[" + $(Get-Date -Format "yyyy-MM-dd HH:mm:ss:fffK") + "]" + "`t")
    }
    #EndRegion
}

process {
    [Version]$assetVersion = $null
    [Uri]$assetUri = $null
    [IO.FileInfo]$tempFile = New-TemporaryFile
    [IO.DirectoryInfo]$modulesDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath @("bootstrap", "modules")

    Write-Information -MessageData "$(Get-Timestamp)Script version: $scriptVersion."
    
    $output = Invoke-RestMethod -Uri "https://api.github.com/repos/bonzosoft/bootstrap/releases/latest"
    $assetVersion = $output.name
    $assetUri = (
        $output |
        Select-Object -ExpandProperty "assets" |
        Where-Object -Property "name" -Like "bootstrap-v*.zip"
    ).browser_download_url
  
    Write-Information -MessageData "$(Get-Timestamp)Downloading version v$assetVersion."
    Invoke-WebRequest -Uri $assetUri -OutFile $tempFile

    Write-Information -MessageData "$(Get-Timestamp)Extracting..."
    Expand-Archive -Path $tempFile -DestinationPath $modulesDirectory.Parent -Force

    Write-Information -MessageData "$(Get-Timestamp)Importing downloaded resources..."
    Import-Module -Name (Get-ChildItem -Path $modulesDirectory -Directory).FullName

    $splat = @{
        Credential   = (Get-Credential)
        Organization = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
        Project      = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
        Environment  = "dev"
    }
    Write-Information -MessageData "$(Get-Timestamp)Creating Vault object..."
    $vault = New-Vault @splat
    Write-Information -MessageData "$(Get-Timestamp)Connecting vault..."
    Connect-Vault -Vault $Vault
    Write-Information -MessageData "$(Get-Timestamp)Creating Repository object..."
    $splat = @{
        Organization = "bonzosoft"
        Name         = "common"
        Branch       = "bw"
        Token        = (Get-VaultSecret -Vault $Vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/" | ConvertTo-SecureString -AsPlainText)
    }
    $repo = New-GitRepository @splat
    Write-Information -MessageData "$(Get-Timestamp)Connecting repository..."
    Connect-GitRepository -Repository $repo

    Write-Information -MessageData "$(Get-Timestamp)Getting repository..."
    Get-GitRepository -Repository $repo

    foreach ($item in @("install", "cmd")) {
        [IO.FileInfo]$source = Join-Path -Path $repo.Path -ChildPath @("${item}.sh")
        [IO.FileInfo]$target = Join-Path -Path ${PWD} -ChildPath @($item)

        Write-Information -MessageData "$(Get-TimeStamp)Creating link for '${item}'."
        $params = @(
            "-snf"
            $source.FullName
            $target.FullName
        )
        $null = ln @params 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message $errorMessage
        }
        Write-Information -MessageData "$(Get-TimeStamp)Setting '${item}' as executable."
        $params = @(
            "+x"
            $source.FullName
        )
        $null = chmod @params 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message $errorMessage
        }
    }
}

end {
    Write-Host "`nPress any key to continue..."
    Read-Host | Out-Null
}
