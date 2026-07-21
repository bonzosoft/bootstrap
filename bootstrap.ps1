#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

begin {
   $ErrorActionPreference = 'Stop'

   [string]$gitDomain = "github.com"
   [string]$gitOrganization = "bonzosoft"
   [string]$gitRepositoryName = "common"
   [string]$gitRepositoryBranch = "bw"
   [string]$gitToken = ""
   [IO.DirectoryInfo]$gitDirectory = Join-Path -Path ${PWD} -ChildPath @("$gitRepositoryName")

   [string]$infDomain = "https://eu.infisical.com"
   [string]$infOrganizationId = "dd2d983e-3db8-40ea-bec4-f69a13b8566a"
   [string]$infProjectId = "9b3eaa39-1cba-4239-b272-9cd10c997eed"
   [pscredential]$infCredential = $null
   [string]$infSession = ""
}

process {
    if (Test-Path -Path $gitDirectory) {
        Push-Location -Path $gitDirectory | Out-Null
        try{
            git fecth origin
            if ($LASTEXITCODE -ne 0) {
                throw
            }
            git checkout $gitRepositoryBranch
            if ($LASTEXITCODE -ne 0) {
                throw
            }
            git reset --hard origin/$gitRepositoryBranch
            if ($LASTEXITCODE -ne 0) {
                throw
            }
        }
        finally {
            Pop-Location | Out-Null
        }
    }
    else {
        $infCredential = Get-Credential -Title "INFISICAL login" -Message "Insert credential for Secrets Vault"
        $infSession = infisical login `
            --domain $domain `
            --email $infCredential.UserName `
            --password ($infCredential.Password | ConvertFrom-SecureString -AsPlainText) `
            --organization-id $infOrganizationId `
            --telemetry $False.ToString() `
            --plain
        if ($LASTEXITCODE -ne 0) {
            throw
        }
        $gitToken = infsical secrets get PWSH_CONTENTS_READONLY_ALL `
            --session $infSession `
            --domain $infDomain `
            --projectId $infProjectId `
            --plain
        if ($LASTEXITCODE -ne 0) {
            throw
        }
        git clone `
            --branch $gitRepositoryBranch `
            --single-branch
            "https://x-access-token:${gitToken}@${gitDomain}/${gitOrganization}/${gitRepositoryName}.git"
        if ($LASTEXITCODE -ne 0) {
            throw
        }
    }
}

end {
    Remove-Item -Path $PSCommandPath -Force | Out-Null
}
