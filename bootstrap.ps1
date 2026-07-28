#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    $ErrorActionPreference = Stop
    $InformationPreference = Continue

    [string[]]$stdStream = @()
    [string[]]$errStream = @()
    [string[]]$params = @()

    # git
    [pscustomobject]$repository = [PSCustomObject]@{}
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Protocol"      -Value [string]"https"
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Domain"        -Value [string]"github.com"
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Organization"  -Value [string]"bonzosoft"
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Name"          -Value [string]"common"
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Branch"        -Value [string]"bw" #main
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Token"         -Value [securestring]$null
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Path"          -Value [IO.DirectoryInfo](Join-Path -Path ${PWD} -ChildPath @($repository.Name))
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Uri"           -Value [uri]($repository.Protocol + "://" + $repository.Domain + "/" + $repository.Organization + "/" + $repository.Name + ".git")
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "GetAuthHeader" -Value {
        if ($null -ne $this.Token) {
            Write-Output -InputObject "Authorization: Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$($this.Token | ConvertFrom-SecureString -AsPlainText)")))"
        }
        else {
            # nop
        }
    }
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "Status"        -Value {
        $params = @(
            "-c",
            "http.extraHeader=$($this.GetAuthHeader())"
            "ls-remote"
            $this.Uri
        )
        $null = git $params 2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Output -InputObject $false
        }
        else {
            Write-Output -InputObject $true
        }
    }

    # infisical
    $vaultConfigFile = [IO.FileInfo](Join-Path -Path ${PWD} -ChildPath @(".config", "infisical.json"))
    [pscustomobject]$vault = [PSCustomObject]@{}
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Credential"   -Value [pscredential]$null
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Domain"       -Value [uri]"https://eu.infisical.com"
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Organization" -Value [guid]"dd2d983e-3db8-40ea-bec4-f69a13b8566a"
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Project"      -Value [guid]"9b3eaa39-1cba-4239-b272-9cd10c997eed"
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Path"         -Value [IO.DirectoryInfo]"/"
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Token"        -Value [securestring](Test-Path -Path $vaultConfigFile ? ((Get-Conent -Path $vaultConfigFile | ConvertFrom-Json).Token | ConvertTo-SecureString -AsPlainText) : $null)
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "Status"       -Value {
        $params = @(
            "login"
            "status"    
            "--domain"
            $this.Domain
            "--token"
            $this.Token | ConvertFrom-SecureString -AsPlainText
        )
        $null = infisical $params 2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Output -InputObject $false
        }
        else {
            Write-Output -InputObject $true
        }
    }

    # configuring software
    $Env:GIT_TERMINAL_PROMPT = 0
    $Env:INFISICAL_DISABLE_UPDATE_CHECK = "true"

    #Region Functions
    function Get-Timestamp {
        Write-Output -InputObject ("[$(Get-Date -Format "yyyy/MM/dd HH:mm:ss:fff K")]`t")
    }
    #EndRegion 
}

process {
    Write-Information -MessageData "$(Get-Timestamp)Checking vault token."
    if ($vault.Status() -ne $true) {
        Write-Information -MessageData "$(Get-Timestamp)Invalid vault token."
        if ($null -eq $vault.Credential) {
            $vault.Credential = Get-Credential  -Message "$(Get-Timestamp)Insert credential for vault '$($vault.Domain)'"
        }

        Write-Information -MessageData "$(Get-TimeStamp)Connection to vault."
        $params = @(
            "login"
            "--domain"
            $vault.Domain
            "--email"
            $vault.Credential.UserName
            "--password"
            $vault.Credential.Password | ConvertFrom-SecureString -AsPlainText
            "--organization-id"
            $vault.Organization
            "--telemetry=false"
            "--plain"
            "--silent"
        )
        $vault.Token = infisical $params 2> Variable:errStream | ConvertTo-SecureString -AsPlainText
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
        else {
            if (-not (Test-Path -Path $vaultConfigFile)) {
                New-Item -Path $vaultConfigFile.Directory -ItemType 'Directory' -Force | Out-Null
            }
            Get-Content -Path $vaultConfigFile | ConvertFrom-Json | ForEach-Object {$PSItem.Token = ($vault.Token | ConvertFrom-SecureString -AsPlainText); Write-Output -InputObject $PSItem} | ConvertTo-Json | Set-Content -Path $vaultConfigFile
        }
    }

    Write-Information -MessageData "$(Get-TimeStamp)Reading Git token from Vault."
    $params = @(
        "secrets"
        "get"
        "GITHUB_CONTENTS_READONLY_ALL"
        "--domain"
        $vault.Doamin
        "--projectId"
        $vault.Project
        "--path"
        $vault.Path
        "--telemetry=false"
        "--plain"
    )
    $repository.Token = infisical $params 2> Variable:errStream | ConvertTo-SecureString -AsPlainText
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message ($errStream -join [Environment]::NewLine)
    }

    if ($repository.Status() -ne $true) {
        Write-Error -Message "$(Get-Timestamp)Unable to connect to git repository." -ErrorAction Stop
    }

    if (Test-Path -Path $repository.Path) {
        Remove-Item -Path $repository.Path -Force -Recurse
    }

    Write-Information -MessageData "$(Get-TimeStamp)Cloning repository '${gitRepositoryName}'."
    $params = @(
        "-c"
        "http.extraHeader=$($repository.GetAuthHeader())"
        "clone"
        "--branch"
        $repository.Branch
        "--single-branch"
        $repository.Uri
    )
    git $params 2> Variable:errStream
    if ($LASTEXITCODE -ne 0) {
        Write-Error -Message ($errStream -join [Environment]::NewLine)
    }

    foreach ($item in @("install", "cmd")) {
        $source = Join-Path -Path $gitDirectory -ChildPath @("${item}.sh")
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
    Write-Host "Press any key to continue..."
    Read-Host | Out-Null
}
