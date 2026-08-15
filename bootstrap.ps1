#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    Clear-Host

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'

    [Version]$scriptVersion = "0.1.3"

    [Hashtable]$repositorySplat = @{
        Organization = "bonzosoft"
        Name         = "common"
        Branch       = "bw"
    }
    [Hashtable]$vaultSplat = @{
        Organization = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
        Project      = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
        Environment  = "dev"
    }


   #[string[]]$stdStream = @()
   #[string[]]$errStream = @()
    [string[]]$params = @()
    [object]$assetInfo = $null
    [Version]$assetVersion = $null
    [Uri]$assetUri = $null
    [IO.FileInfo]$tempFile = New-TemporaryFile
    [IO.FileInfo]$infoFile = Join-Path -Path $PWD -ChildPath @(".config", "deployment.json")
    [IO.DirectoryInfo]$modulesDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath @("bootstrap", "modules")

    #Region Local functions
    function Get-Timestamp {
        Write-Output -InputObject ("[" + $(Get-Date -Format "yyyy-MM-dd HH:mm:ss:fffK") + "]" + "`t")
    }
    #EndRegion
}

process {
    Write-Information -MessageData "$(Get-Timestamp)Starting script. Version: v$scriptVersion."


    Write-Information -MessageData "$(Get-Timestamp)Getting assets metadata."
    $assetInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/bonzosoft/bootstrap/releases/latest"
    $assetVersion = $assetInfo.name
    $assetUri = (
        $assetInfo |
        Select-Object -ExpandProperty "assets" |
        Where-Object -Property "name" -Like "bootstrap-v*.zip"
    ).browser_download_url
    Remove-Variable -Name "assetInfo"
  

    Write-Information -MessageData "$(Get-Timestamp)Downloading assets. Version: v$assetVersion."
    Invoke-WebRequest -Uri $assetUri -OutFile $tempFile


    Write-Information -MessageData "$(Get-Timestamp)Extracting assets."
    if (Test-Path -Path $modulesDirectory.Parent) {
        Remove-Item -Path $modulesDirectory.Parent -Force
    }
    Expand-Archive -Path $tempFile -DestinationPath $modulesDirectory.Parent -Force


    Write-Information -MessageData "$(Get-TImestamp)Removing temporary data"
    Remove-Item -Path $tempFile
    Remove-Variable -Name "tempFile"


    Write-Information -MessageData "$(Get-Timestamp)Importing assets."
    Import-Module -Name (Get-ChildItem -Path $modulesDirectory -Directory -Depth 1).FullName

    Write-Information -MessageData "$(Get-Timestamp)Starting vault connection."

    Write-Information -MessageData "$(Get-Timestamp)Creating Repository object..."
    $repository = New-GitRepository @repositorySplat
    if (Test-Path -Path $infoFile) {
        Write-Information -MessageData "$(Get-Timestamp)Trying to fecth token from local storage."
        $repository.Token = (Get-Content -Path $infoFile -Raw | ConvertFrom-Json -AsHashtable).Git.Token | ConvertTo-SecureString -AsPlainText -ErrorAction 'SilentlyContinue'
    }

    if (!(Test-GitRepository -Repository $repository)) {
        Write-Information -MessageData "$(Get-Timestamp)Trying to fetch token from vault."


        $vaultSplat += @{
            Credential   = (Get-Credential)
        }


        Write-Information -MessageData "$(Get-Timestamp)Creating Vault object."
        $vault = New-Vault @vaultSplat


        Write-Information -MessageData "$(Get-Timestamp)Connecting vault."
        Connect-Vault -Vault $Vault -ErrorAction 'Stop'


        Write-Information -MessageData "$(Get-Timestamp)Fetching token from vault."
        $repository.Token = Get-VaultSecret -Vault $Vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/" | ConvertTo-SecureString -AsPlainText -ErrorAction 'Stop'
    }

    Write-Information -MessageData "$(Get-Timestamp)Connecting repository."
    Connect-GitRepository -Repository $repository -ErrorAction 'Stop'


    Write-Information -MessageData "$(Get-Timestamp)Getting repository."
    Get-GitRepository -Repository $repository


    Write-Information -MessageData "$(Get-Timestamp)Storing token."
    if (!(Test-Path -Path $infoFile.Directory)) {
        New-Item -Path $infoFile.Directory -ItemType 'Directory' -Force | Out-Null
    }
    @{
        "Git" = @{
            "Token" = ($repository.Token | ConvertFrom-SecureString -AsPlainText)
        }
    } | ConvertTo-Json -Depth 9 | Set-Content -Path $infoFile


    foreach ($item in @("cmd")) {
        [IO.FileInfo]$source = Join-Path -Path $repository.Path -ChildPath @("${item}.sh")
        [IO.FileInfo]$target = Join-Path -Path ${PWD} -ChildPath @($item)

        Write-Information -MessageData "$(Get-TimeStamp)Creating link for '${item}'."
        $splat = @(
            Path = $source
            Value = $target
            ItemType = 'SymbolicLink'
            Force = $true
        )
        New-Item @splat # sames as native command: ln -snf $source.FulName $target.FullName
        

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
    Write-Information -MessageData "$([Environment]::NewLine)Press any key to continue..."
    Read-Host | Out-Null
}
