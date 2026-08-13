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
    [PSCustomObject]$vault = $null
    [string]$token = ""

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
    $vault = New-Vault @splat
    Connect-Vault -Vault $Vault
    $token = Get-VaultSecret -Vault $Vault -Name "GITHUB_CONTENTS_READONLY_COMMON" -Path "/"
    Write-Host "token: $token"
    return


    Write-Information -MessageData "$(Get-Timestamp)Checking vault connection."
    if ($vault.Status() -ne $true) {
        Write-Information -MessageData "$(Get-Timestamp)Invalid vault connection."
        if ($null -eq $vault.Credential) {
            $vault.Credential = Get-Credential -Title "Vault credential request" -Message "Enter credential for vault '$($vault.Domain.ToString())':"
        }

        Write-Information -MessageData "$(Get-TimeStamp)Starting vault connection."
        $params = @(
            "login"
            "--domain"
            $vault.Domain.ToString()
            "--email"
            $vault.Credential.UserName
            "--password"
            $vault.Credential.Password | ConvertFrom-SecureString -AsPlainText
            "--organization-id"
            $vault.Organization.ToString()
            "--telemetry=false"
            "--plain"
            "--silent"
        )
        $vault.Token = infisical $params 2> Variable:errStream | ConvertTo-SecureString -AsPlainText
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine) -ErrorAction 'Stop'
        }

        Write-Information -MessageData "$(Get-Timestamp)Persisting vault token."
        if (!(Test-Path -Path $vault.GetCredentialPath())) {
            New-Item -Path $vault.GetCredentialPath().Directory -ItemType 'Directory' -Force | Out-Null
        }
        Set-Content -Path $vault.GetCredentialPath() -Value ($vault.Token | ConvertFrom-SecureString -AsPlainText) -Force
    }

    Write-Information -MessageData "$(Get-TimeStamp)Getting repository token from vault."
    $params = @(
        "secrets"
        "get"
        "GITHUB_PWSH_CONTENTS_READONLY_COMMON"
        "--domain"
        $vault.Domain.ToString()
        "--projectId"
        $vault.Project.ToString()
        "--path"
        $vault.Path.FullName
        "--token"
        $vault.Token | ConvertFrom-SecureString -AsPlainText
        "--telemetry=false"
        "--plain"
    )
    $repository.Token = infisical $params 2> Variable:errStream | ConvertTo-SecureString -AsPlainText
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message ($errStream -join [Environment]::NewLine)
    }

    Write-Information -MessageData "$(Get-Timestamp)Checking repository connection."
    if (!$repository.Status()) {
        Write-Error -Message "$(Get-Timestamp)Unable to reach remote source." -ErrorAction 'Stop'
    }

    if ($repository.IsRepository()) {
        Write-Information -MessageData "$(Get-Timestamp)Existing repository '$($repository.Name)'. Deleting."
        Remove-Item -Path $repository.Path.FullName -Force -Recurse
    }
    else {
        if (Test-Path -Path $repository.Path) {

        }      
    }

    ## login
    $repository.GetAuthHeader() | git -c credential.helper=cache credential approve

    #@(
    #    "protocol=$($repository.Domain.Scheme)"
    #    "host=$($repository.Domain.Host)"
    #    "username=x-access-token"
    #    "password=$(repository.Token | ConvertFrom-SecureString -AsPlainText)"
    #) | git -c credential.helper=cache credential approve

    Write-Information -MessageData "$(Get-TimeStamp)Cloning repository '$($repository.Name)'."
    $repository.OpenConnection()
    $params = @(
        "-c"
        #"http.extraHeader=$($repository.GetAuthHeader())"
        #"credential.helper=store --file=$repositoryConfigFile"
        "credential.helper=cache"
        "clone"
        "--branch"
        $repository.Branch
        "--single-branch"
        $repository.Uri.AbsoluteUri
    )
    git $params 2> Variable:errStream
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message ($errStream -join [Environment]::NewLine)
    }
    $repository.CloseConnection()

    #@(
    #    "protocol=$($repository.Domain.Scheme)"
    #    "host=$($repository.Domain.Host)"
    #    "username=x-access-token"
    #) | git -c credential.helper=cache credential reject
    #o
    # git credential-cache exit

    foreach ($item in @("install", "cmd")) {
        $source = Join-Path -Path $repository.Path -ChildPath @("${item}.sh")
        $target = Join-Path -Path ${PWD} -ChildPath @($item)

        Write-Information -MessageData "$(Get-TimeStamp)Creating link for '${item}'."
        $null = ln -snf $source $target  2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message $errorMessage
        }
        Write-Information -MessageData "$(Get-TimeStamp)Setting '${item}' as executable."
        $null = chmod +x $target 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message $errorMessage
        }
    }
}

end {
    Write-Host "`nPress any key to continue..."
    Read-Host | Out-Null
}
