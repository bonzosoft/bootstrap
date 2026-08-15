#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    


    Clear-Host
    [Version]$scriptVersion = "0.4.3"
    



    [Hashtable]$splat = @{}
    [string[]]$stdStream = @()
    [string[]]$errStream = @()
    [string[]]$params = @()
    
    [Uri]$assetUri = $null
    [Version]$assetVersion = $null
    [IO.FileInfo]$assetTempFile = $null

    [Hashtable]$repositorySplat = @{
        Domain       = "https://github.com"
        Organization = "bonzosoft"
        Name         = "common"
        Branch       = "bw"
        #Token        = ((Get-Content -Path $configFile -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 9).Vault.Token | ConvertTo-SecureString -AsPlainText -ErrorAction 'SilentlyContinue')
    }
    [Hashtable]$vaultSplat = @{
        Domain       = "https://eu.infisical.com"
        Organization = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
        Project      = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
        Environment  = "dev"
        #Token        = ((Get-Content -Path $configFile -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 9).Git.Token | ConvertTo-SecureString -AsPlainText -ErrorAction 'SilentlyContinue')
    }

    [IO.FileInfo]$configFile = Join-Path -Path $PWD -ChildPath @(".config", "config.json")
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
    $assetVersion, $assetUri = 
        Invoke-RestMethod -Uri "https://api.github.com/repos/bonzosoft/bootstrap/releases/latest" |
            ForEach-Object -Process {
                Write-Output -InputObject $PSItem.name
                Write-Output -InputObject (
                    $PSItem | 
                    Select-Object -ExpandProperty "assets" |
                    Where-Object -Property "name" -Like "bootstrap-v*.zip"
                ).browser_download_url
            }


    Write-Information -MessageData "$(Get-Timestamp)Downloading assets. Version: v$assetVersion."
    $assetTempFile = New-TemporaryFile
    Invoke-WebRequest -Uri $assetUri -OutFile $assetTempFile


    Write-Information -MessageData "$(Get-Timestamp)Extracting assets."
    if (Test-Path -Path $modulesDirectory.Parent) {
        Remove-Item -Path $modulesDirectory.Parent -Force
    }
    Expand-Archive -Path $assetTempFile -DestinationPath $modulesDirectory.Parent -Force


    Write-Information -MessageData "$(Get-Timestamp)Importing assets."
    Import-Module -Name (Get-ChildItem -Path $modulesDirectory -Directory).FullName


    Write-Information -MessageData "$(Get-TImestamp)Removing temporary data."
    Remove-Item -Path $assetTempFile
    Remove-Variable -Name "assetTempFile"


    Write-Information -MessageData "$(Get-Timestamp)Getting local data."
    $configFileData = Get-Content -Path $configFile -ErrorAction 'SilentlyContinue' | ConvertFrom-Json -Depth 9

    if (($null -ne $configFileData) -and ($configFileData.Keys -contains "Git")) {
        if ($configFileData.Git.Keys -contains "Token") {
            $repositorySplat.Token = $configFileData.Git.Token | ConvertTo-SecureString -AsPlainText
        }
    }
    if (($null -ne $configFileData) -and ($configFileData.Keys -contains "Vault")) {
        if ($configFileData.Git.Keys -contains "Token") {
            $vaultSplat.Token = $configFileData.Git.Token | ConvertTo-SecureString -AsPlainText
        }
    }


    Write-Information -MessageData "$(Get-Timestamp)Creating Repository object."
    $repository = New-GitRepository @repositorySplat

    if (!Test-GitRepository -Repository $repository) {
        if (!Test-Vault -Vault $vault) {
            $vaultSplat.Remove("Token")

            Write-Information -MessageData "$(Get-Timestamp)Trying to fetch token from vault."
            do {
                $vaultSplat.Credential = (Get-Credential)
    
                Write-Information -MessageData "$(Get-Timestamp)Creating Vault object."
                $vault = New-Vault @vaultSplat
    
                Write-Information -MessageData "$(Get-Timestamp)Connecting vault."
                try {
                    Connect-Vault -Vault $Vault -ErrorAction 'Stop'
                }
                catch {
                    continue
                }
                break
            }
            while ($true)
        }

        
        Write-Information -MessageData "$(Get-Timestamp)Fetching token from vault."
        $repository.Token = Get-VaultSecret -Vault $Vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/" | ConvertTo-SecureString -AsPlainText -ErrorAction 'Stop'
    }


    Write-Information -MessageData "$(Get-Timestamp)Connecting repository."
    Connect-GitRepository -Repository $repository -ErrorAction 'Stop'


    Write-Information -MessageData "$(Get-Timestamp)Getting repository."
    Get-GitRepository -Repository $repository


    Write-Information -MessageData "$(Get-Timestamp)Storing token."
    if (!(Test-Path -Path $configFile.Directory)) {
        New-Item -Path $configFile.Directory -ItemType 'Directory' -Force | Out-Null
    }
    @{
        "Git" = @{
            "Token" = ($repository.Token | ConvertFrom-SecureString -AsPlainText)
        }
    } | ConvertTo-Json -Depth 9 | Set-Content -Path $configFile


    foreach ($item in @("pwsh")) {
        [IO.FileInfo]$source = Join-Path -Path $PWD -ChildPath @("common", "${item}.sh") #Join-Path -Path $repository.Path -ChildPath @("${item}.sh")
        [IO.FileInfo]$target = Join-Path -Path ${PWD} -ChildPath @($item)

        Write-Information -MessageData "$(Get-TimeStamp)Creating link for '${item}'."
        $splat = @{
            Path     = $target
            Value    = $source
            ItemType = 'SymbolicLink'
            Force    = $true
        }
        New-Item @splat | Out-Null # sames as native command: ln -snf $source.FulName $target.FullName
        

        Write-Information -MessageData "$(Get-TimeStamp)Setting '${item}' as executable."
        $params = @(
            "+x"
            $source.FullName
        )
        $stdStream = chmod @params 2> variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
    }
}

end {
    Write-Information -MessageData ""
    Write-Information -MessageData "Press any key to continue..."
    Read-Host | Out-Null
}
