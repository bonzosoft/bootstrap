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

    # configuring tools
    $Env:GIT_TERMINAL_PROMPT = 0
    $Env:INFISICAL_DISABLE_UPDATE_CHECK = "true"
    $vaultConfigFile = [IO.FileInfo](Join-Path -Path ${PWD} -ChildPath @(".config", "infisical"))
    $repositoryConfigFile = [IO.FileInfo](Join-Path -Path ${PWD} -ChildPath @(".config", "git"))

    #Region Vault object
    [pscustomobject]$vault = [PSCustomObject]@{}
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Credential"   -Value ([pscredential]$null)
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Domain"       -Value ([uri]"https://eu.infisical.com")
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Organization" -Value ([guid]"dd2d983e-3db8-40ea-bec4-f69a13b8566a")
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Project"      -Value ([guid]"9b3eaa39-1cba-4239-b272-9cd10c997eed")
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Path"         -Value ([IO.DirectoryInfo](Join-Path -Path "/" -ChildPath @()))
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Token"        -Value ([securestring](Get-Content -Path $vaultConfigFile -ErrorAction 'SilentlyContinue' | ConvertTo-SecureString -AsPlainText -ErrorAction 'SilentlyContinue'))
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "Status"       -Value {
        if ($null -eq $this.Token) {
            return $false
        }
        else {
            $params = @(
                "login"
                "status"
                "--domain"
                $this.Domain.ToString()
                "--token"
                $this.Token | ConvertFrom-SecureString -AsPlainText
                "telemetry=false"
            )
            $null = infisical $params 2> $null
            if ($LASTEXITCODE -ne 0) {
                return $false
            }
            else {
                return $true
            }
        }
    }
    #EndRegion 

    #Region Git object
    [pscustomobject]$repository = [pscustomobject]@{}
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Domain" -Value ([uri]"https://github.com")
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Organization" -Value ([string]"bonzosoft")
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Name" -Value ([string]"common")
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Branch" -Value ([string]"bw") #main
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Token" -Value ([securestring]$null)
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Uri" -Value ([uri]($repository.Domain.ToSTring() + $repository.Organization.ToString() + "/" + $repository.Name + ".git"))
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Path" -Value ([IO.DirectoryInfo](Join-Path -Path ${PWD} -ChildPath @($repository.Name)))
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "GetAuthHeader" -Value {
        if ($null -eq $this.Token) {
            return
        }
        else {
            return ($this.Domain.Scheme + "://" + "x-auth-token" + ":" + ($this.Token | ConvertFrom-SecureString -AsPlainText) + "@" + $this.Domain.Host)
            #return "Authorization: Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$($this.Token | ConvertFrom-SecureString -AsPlainText)")))"
        }
    }
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "Status"        -Value {
        if ($null -eq $this.Token) {
            return $false
        }
        else {
            $params = @(
                "-c",
                #"http.extraHeader=$($this.GetAuthHeader())"
                "credential.helper=store --file=$repositoryConfigFile"
                "ls-remote"
                $this.Uri.AbsoluteUri
            )
            $null = git $params 2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
                return $false
            }
            else {
                return $true
            }
        }
    }
    #EndRegion

    #Region Functions
    function Get-Timestamp {
        Write-Output -InputObject ("[" + $(Get-Date -Format "yyyy-MM-dd HH:mm:ss:fffK") + "]" + "`t")
    }
    #EndRegion 
}

process {
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
        if (-not (Test-Path -Path $vaultConfigFile.Directory)) {
            New-Item -Path $vaultConfigFile.Directory -ItemType 'Directory' -Force | Out-Null
        }
        Set-Content -Path $vaultConfigFile -Value ($vault.Token | ConvertFrom-SecureString -AsPlainText) -Force
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

    Write-Information -MessageData "$(Get-Timestamp)Persisting repository token."
    if (-not (Test-Path -Path $repositoryConfigFile.Directory)) {
        New-Item -Path $repositoryConfigFile.Directory -ItemType 'Directory' -Force | Out-Null
    }
    Set-Content -Path $repositoryConfigFile -Value $repository.GetAuthHeader() -Force

    Write-Information -MessageData "$(Get-Timestamp)Checking repository connection."
    if ($repository.Status() -ne $true) {
        Write-Error -Message "$(Get-Timestamp)Invalid repository connection." -ErrorAction 'Stop'
    }

    if (Test-Path -Path $repository.Path.FullName) {
        Write-Information -MessageData "$(Get-Timestamp)Existing repository '$($repository.Name)'. Deleting."
        Remove-Item -Path $repository.Path.FullName -Force -Recurse
    }

    Write-Information -MessageData "$(Get-TimeStamp)Cloning repository '$($repository.Name)'."
    $params = @(
        "-c"
        #"http.extraHeader=$($repository.GetAuthHeader())"
        "credential.helper=store --file=$repositoryConfigFile"
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
