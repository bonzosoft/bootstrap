#! /usr/bin/env pwsh

<#
    .SYNOPSIS
        Bootstrap script.

    .DESCRIPTION


    .PARAMETER Force
        When present, overrides the local credentials.

    .INPUTS
        Switch

    .OUTPUTS
        Void

    .NOTES
        Author: Bonzosoft (C) 2026
#>

#using namespace System.Management.Automation
#using namespace System.IO

[CmdletBinding()]
[OutputType([void])]
param()

try {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'
    
    #Region ── Constants ───────────────────────────────────────────────────────────
    [IO.FIleInfo]$thisScript = $PSCommandPath
    
    [IO.FIleInfo]$configFile = 
        Join-Path `
            -Path      $PWD `
            -ChildPath @(".config", "config.json")
    
    [hashtable]$configData = @{
        Git = [hashtable]@{
            Token = ""
        }
        Vault = [hashtable]@{
            Client = [hashtable]@{
                Id     = ""
                Secret = ""
            }
        }
    }
    
    <#
    [hashtable]$configDataSchema = [ordered]@{
        type = "object"
        required = @("Git", "Vault")
        properties = @{
            Git = @{
                type = "object"
                required = @("Token")
                properties = @{
                    Token = @{
                        type = "string"
                    }
                }
            }
            Vault = @{
                type = "object"
                required = @("Client")
                properties = @{
                    Client = @{
                        type = "object"
                        required = @("Id", "Secret")
                        properties = @{
                            Id = @{
                                type = "string"
                            }
                            Secret = @{
                                type = "string"
                            }
                        }
                    }
                }
            }
        }
    }
    #>
    
    [hashtable]$vaultSplat = [hashtable]@{
        Domain       = "https://eu.infisical.com"
        Organization = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
        Project      = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
        Environment  = "dev"
    }
    
    [hashtable]$commonRepositorySplat = [hashtable]@{
        Domain       = "https://github.com"
        Organization = "bonzosoft"
        Name         = "common"
        Branch       = "bw"
    }
    
    [hashtable]$bootstrapRepositorySplat = [hashtable]@{
        Domain       = "https://github.com"
        Organization = "bonzosoft"
        Name         = "bootstrap"
        Branch       = "main"
    }
    
    [hashtable]$splat = $null
    #EndRegion ─────────────────────────────────────────────────────────────────────
    
    
    Clear-Host
    
    
    [uri]$assetUri = $null
    [version]$assetVersion = $null
    Write-Information -MessageData "Fetching asset release information from '$($bootstrapRepositorySplat.Name)'."
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
    
    
    [IO.FIleInfo]$assetTempFile = New-TemporaryFile
    Write-Information -MessageData "Fetching asset release v$assetVersion."
    Invoke-WebRequest -Uri $assetUri -OutFile $assetTempFile
    
    
    #[IO.DirectoryInfo]$modulesTempDirectory = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath @([IO.Path]::GetRandomFileName(), "modules")
    [IO.DirectoryInfo]$modulesTempDirectory = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath @("bootstrap", "modules")
    Write-Information -MessageData "Extracting asset to '$modulesTempDirectory'."
    Expand-Archive -Path $assetTempFile -DestinationPath $modulesTempDirectory.Parent -Force


    Write-Information -MessageData "Removing leftovers."
    Remove-Item -Path $assetTempFile -Force
    

    Write-Information -MessageData "Loading asset."
    Import-Module -Name (Get-ChildItem -Path $modulesTempDirectory -Directory).FullName
    

    "Starting bootstrap script." | Write-Log
    

    "Reading local configuration." | Write-Log
    $configData = Merge-Hashtable -Left $configData -Right (Get-Content -Path $configFile | ConvertFrom-Json -Depth 9 -AsHashTable) -MergeHashtables -MergeArrays
    
    
    $vaultSplat.Credential = $null
    if ((-not [string]::IsNullOrWhiteSpace($configData.Vault.Client.Id)) -or (-not [string]::IsNullOrWhiteSpace($configData.Vault.Client.Secret))) {
        :doWhile do {
            switch (Read-Host -Prompt "Local credentials for Vault already exist. Replace them? [Y]es / [N]o") {
                "y" {
                    break doWhile
                }
                "n" {
                    $vaultSplat.Credential = [PSCredential]::new($configData.Vault.Client.Id, ($configData.Vault.Client.Secret | ConvertTo-SecureString -AsPlainText))
                    break doWhile
                }
                default {
                    Write-Host -Message "Unknown option '$PSItem'."
                }
            }
        }
        while ($true)
    }
    
    if ($null -eq $vaultSplat.Credential) {
        $vaultSplat.Credential = (Get-Credential)
    }

    
    "Creating vault object." | Write-Log
    [pscustomobject]$vault = $null
    $vault = New-Vault @vaultSplat
    Write-Log -Success
    

    "Connecting to vault." | Write-Log
    Connect-Vault -Vault $vault
    Write-Log -Success


    "Fetching repository token from vault." | Write-Log
    $commonRepositorySplat.Token = Get-VaultSecret -Vault $vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/" #| ConvertTo-SecureString -AsPlainText -ErrorAction 'Stop'
    Write-Log -Success
    $commonRepositorySplat

    exit
    
    "Creating repository object." | Write-Log
    [pscustomobject]$repository = $null
    $repository = New-GitRepository @commonRepositorySplat
    Write-Log -Success
    

    "Connecting to repository '$($repository.Name)'." | Write-Log
    Connect-GitRepository -Repository $repository -ErrorAction 'Stop'
    Write-Log -Success
    

    "Fetching repository '$($repository.Name)'." | Write-Log
    Import-GitRepository -Repository $repository
    Write-Log -Success
    
    
    [IO.FIleInfo]$source = $null
    [IO.FIleInfo]$target = $null
    foreach ($item in @("pwsh")) {
        $source = Join-Path -Path $PWD -ChildPath @($($repository.Name), "${item}.sh")
        $target = Join-Path -Path $PWD -ChildPath @($item)
    
        if (Test-Path -Path $source) {
            "Creating link for '${item}'." | Write-Log
            $splat = @{
                Path     = $target
                Value    = $source
                ItemType = 'SymbolicLink'
                Force    = $true
            }
            New-Item @splat | Out-Null
            <#
            ## equivalent to: ln -snf $source.FulName $target.FullName
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
            $splat = @{
                Command = "chmod"
                ArgumentList = @(
                    "+x", $source.FullName
                )
            }
            Invoke-NativeCommand @splat -ErrorAction 'Stop'
            Write-Log -Success
        }
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
    $configData.Vault.Client.Id     = Get-VaultSecret -Vault $vault -Name "INFISICAL_CLIENTID_READONLY_BOOTSTRAP" -Path "/"
    $configData.Vault.Client.Secret = Get-VaultSecret -Vault $vault -Name "INFISICAL_CLIENTSECRET_READONLY_BOOTSTRAP" -Path "/"
    
    $configData | ConvertTo-Json -Depth 9 | Set-Content -Path $configFile
    Write-Log -Success
    
    
    #. (Join-Path -Path $PWD -ChildPath @($commonRepositorySplat.Name, "install.ps1"))
    ################################################################################## continuar en install.ps1 a partir de aqui
}
catch {
    Write-Error -ErrorRecord $PSItem
    continue
}
finally {
    "Press any key to continue..." | Write-Log
    Read-Host | Out-Null
}
