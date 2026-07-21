#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
    $ErrorActionPreference = 'Stop'
    $InformationPreference = 'Continue'

    #[string[]]$stdStream = @()
    [string[]]$errStream = @()
    # git
    [string]$gitDomain = "github.com"
    [string]$gitOrganization = "bonzosoft"
    [string]$gitRepositoryName = "common"
    [string]$gitRepositoryBranch = "bw"
    [string]$gitToken = ""
    [IO.DirectoryInfo]$gitDirectory = Join-Path -Path ${PWD} -ChildPath @("$gitRepositoryName")

    # infisical
    [string]$infDomain = "https://eu.infisical.com"
    [string]$infOrganizationId = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
    [string]$infProjectId = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
    [pscredential]$infCredential = $null
    [string]$infSession = ""

    function Get-Timestamp {
        Write-Output -InputObject ("[$(Get-Date -Format "yyyy/MM/dd HH:mm:ss:fff K")]`t")
    }
}

process {
    if (Test-Path -Path $gitDirectory) {
        Push-Location -Path $gitDirectory | Out-Null
        try{
            Write-Information -MessageData "$(Get-TimeStamp)Updating existing repository."
            git fetch origin 2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
                Write-Error -Message ($errStream -join [Environment]::NewLine)
            }
            git checkout $gitRepositoryBranch 2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
                Write-Error -Message ($errStream -join [Environment]::NewLine)
            }
            git reset --hard origin/$gitRepositoryBranch 2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
                Write-Error -Message ($errStream -join [Environment]::NewLine)
            }
        }
        finally {
            Pop-Location | Out-Null
        }
    }
    else {
        $infCredential = Get-Credential -Title "INFISICAL login" -Message "Insert credential for Secrets Vault"

        Write-Information -MessageData "$(Get-TimeStamp)Configuring Vault."
        $Env:INFISICAL_DISABLE_UPDATE_CHECK = $True.ToString()
        infisical vault set file 2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }

        Write-Information -MessageData "$(Get-TimeStamp)Logging into Vault."
        $infSession = infisical login `
            --domain $infDomain `
            --email $infCredential.UserName `
            --password ($infCredential.Password | ConvertFrom-SecureString -AsPlainText) `
            --organization-id $infOrganizationId `
            --telemetry $False.ToString() `
            --plain `
            --silent `
            2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
        $infSession | Set-Content -Path ./infSession
        
        Write-Information -MessageData "$(Get-TimeStamp)Reading Git token from Vault."
        #$Env:INFISICAL_TOKEN = $infSession
        $gitToken = infisical secrets get PWSH_CONTENTS_READONLY_ALL `
            --domain $infDomain `
            --projectId $infProjectId `
            --plain `
            2> Variable:errStream
            if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
        
        Write-Information -MessageData "$(Get-TimeStamp)Cloning repository '${gitRepositoryName}'."
        git clone `
            --branch $gitRepositoryBranch `
            --single-branch `
            "https://x-access-token:${gitToken}@${gitDomain}/${gitOrganization}/${gitRepositoryName}.git" `
            2> Variable:errStream
        # mas seguro, pero require gestion del token
        #git -c http.extraHeader="Authorization: Bearer ${gitToken}" clone `
        #    --branch $gitRepositoryBranch `
        #    --single-branch `
        #    "https://${gitDomain}/${gitOrganization}/${gitRepositoryName}.git" `
        #    2> Variable:errStream
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message ($errStream -join [Environment]::NewLine)
        }
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
