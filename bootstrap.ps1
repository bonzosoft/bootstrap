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
    $Env:INFISICAL_DISABLE_UPDATE_CHECK = "true"

    #Region Vault object
    [pscustomobject]$vault = [PSCustomObject]@{}
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Credential" -Value ([pscredential]$null)
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Domain" -Value ([uri]"https://eu.infisical.com")
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Organization" -Value ([guid]"dd2d983e-3db8-40ea-bec4-f69a13b8566a")
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Project" -Value ([guid]"9b3eaa39-1cba-4239-b272-9cd10c997eed")
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Path" -Value ([IO.DirectoryInfo](Join-Path -Path "/" -ChildPath @()))
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Environment" -Value "dev"
    $vault | Add-Member -MemberType 'NoteProperty' -Name "Token" -Value ([securestring]$null)
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "Login" -Value {
        $params = @(
            "login"
            "--domain"
            $this.Domain.AbsoluteUri
            "--email"
            $this.Credential.UserName
            "--password"
            $this.Credential.Password | ConvertFrom-SecureString -AsPlainText
            "--organization-id"
            $this.Organization.Guid
            "--telemetry=false"
            "--plain"
            "--silent"
        )
        $this.Token = infisical $params 2> Variable:errStream | ConvertTo-SecureString -AsPlainText
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "Logout" -Value {
        $this.Token = [securestring]::new()

        if (Test-Path -Path $this.GetCredentialPath()) {
            Remove-Item -Path $this.GetCredentialPath() -Force
        }
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "StartConnection" -Value {
        if ($null -eq $this.Token) {
            return #Write-Error -Message "No valid token found." -ErrorAction 'Stop'
        }
        Set-Item -Path "Env:INFISICAL_TOKEN" -Value ($this.Token | ConvertFrom-SecureString -AsPlainText)
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "StopConnection" -Value {
        Remove-Item -Path "Env:INFISICAL_TOKEN" -Force -ErrorAction 'SilentlyContinue'
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "Status" -Value {
        $params = @(
            "login"
            "status"
            "--domain"
            $this.Domain.AbsoluteUri
            "--telemetry=false"
        )
        $this.StartConnection()
        try {
            $null = infisical $params 2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
                Write-Debug -Message ($errStream -join [Environment]::NewLine)
                return $false
            }
            return $true
        }
        finally {
            $this.StopConnection()
        }
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "GetCredentialPath" -Value {
        return [IO.FileInfo]::new((Join-Path -Path $PWD.Path -ChildPath @(".config", "infisical")))
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "SaveCredential" -Value {
        if ($null -eq $this.Token) {
            Write-Debug -Message "No token available."
            return
        }

        if (-not (Test-Path -Path $this.GetCredentialPath().Directory)) {
            New-Item -Path $this.GetCredentialPath() -ItemType 'Directory' -Force | Out-Null
        }
        $this.Token | ConvertFrom-SecureString -AsPlainText | Set-Content -Path $this.GetCredentialPath() -Force
    }
    $vault | Add-Member -MemberType 'ScriptMethod' -Name "RestoreCredential" -Value {
        $credentialFile = $this.GetCredentialPath()
        if (-not (Test-Path -Path $credentialFile)) {
            return
        }
        $this.Token = Get-Content -Path $credentialFile | ConvertTo-SecureString -AsPlainText
    }
    $vault.Token = $vault.RestoreCredential()
    #EndRegion 

    #Region Git object
    [pscustomobject]$repository = [pscustomobject]@{}
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Domain" -Value ([uri]"https://github.com")
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Organization" -Value ([string]"bonzosoft")
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Name" -Value ([string]"common")
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Branch" -Value ([string]"bw") #main
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Token" -Value ([securestring]$null)
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Path" -Value ([IO.DirectoryInfo]::new((Join-Path -Path $PWD -ChildPath @($repository.Name))))
    $repository | Add-Member -MemberType 'NoteProperty' -Name "Uri" -Value ([uri]::new($repository.Domain, $repository.Organization + "/" + $repository.Name + ".git"))
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "OpenConnection" -Value {
        if ($null -eq $this.Token) {
            return
        }
        $params = @(
            "-c" 
            "credential.interactive=false"
            "-c" 
            "credential.helper=cache"
            "credential"
            "approve"
        )
        @(
            "protocol=" + $this.Domain.Scheme
            "host=" + $this.Domain.Host
            "username=x-access-token"
            "password=" + ($this.Token | ConvertFrom-SecureString -AsPlainText -ErrorAction 'SilentlyContinue')
        ) | git $params 2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
        return
    }
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "CloseConnection" -Value {
        $params = @(
            "-c" 
            "credential.interactive=false"
            "-c" 
            "credential.helper=cache"
            "credential"
            "reject"  
        )
        @(
            "protocol=" + $this.Domain.Scheme
            "host=" + $this.Domain.Host
            "username=x-access-token"
        ) | git $params 2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
        return
    }
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "Status" -Value {
        $params = @(
            "-c" 
            "credential.interactive=false"
            "-c" 
            "credential.helper=cache"
            "ls-remote"
            $this.Uri.AbsoluteUri
        )
        $this.OpenConnection()
        try {
            $null = git $params 2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
                Write-Debug -Message ($errStream -join [Environment]::NewLine)
                return $false
            }
            return $true
        }
        finally {
            $this.CloseConnection()
        }
    }
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "IsRepository" -Value {
        $params = @(
            "-C"
            $this.Path.FullName
            "rev-parse"
            "--is-inside-work-tree"
        )
        $null = git $params 2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Debug -Message ($errStream -join [Environment]::NewLine)
            return $false
        }
        return $true
    }
    $repository | Add-Member -MemberType 'ScriptMethod' -Name "Refresh" -Value {
        param ([IO.DirectoryInfo]$Directory = $this.Path.Parent)

        $this.Path = ([IO.DirectoryInfo]::new((Join-Path -Path $Directory -ChildPath @($this.Name))))
        $this.Uri = ([uri]::new($this.Domain, $this.Organization + "/" + $this.Name + ".git"))
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
        if (-not (Test-Path -Path $vault.GetCredentialPath())) {
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
    if (-not $repository.Status()) {
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
