#!/usr/bin/env pwsh

### SINGLETON ##################################################################
$singleton = ([IO.FileInfo]$PSCommandPath).BaseName.Replace(".","_").ToUpper()
if (Get-Variable -Name "__INCLUDED_$singleton" -Scope Global -ErrorAction SilentlyContinue) {
    return
}
else {
    New-Variable -Name "__INCLUDED_$singleton" -Scope Global -Value $true
}
Write-Information -Message "Loading script '$PSCommandPath'."


### LOAD COMMON ASSETS #########################################################
. (Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "common.ps1"))


## SELECT TENANT ################################################################
Switch-DockerTenant


## PULL SUBMODULES #############################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    Write-Information -Message "Pulling submodules."
    $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
    if ($LASTEXITCODE) {
        throw ($errorVariable | Out-String)
    }
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Name DATADIR                -Value $Script:Context.DataDir.FullName
Set-DockerVariable -Name PUID                   -Value $Script:Context.PUID
Set-DockerVariable -Name PGID                   -Value $Script:Context.PGID
Set-DockerVariable -Name SOCKETPROXY_PGID       -Value (Get-DockerGid)                      -NoAppend
Set-DockerVariable -Name DOMAIN                 -Value $Script:Context.Domain               -NoAppend
Set-DockerVariable -Name SMTP_HOSTNAME          -Value $Script:Context.SmtpHostname         -NoAppend
Set-DockerVariable -Name SMTP_HOSTPORT              -Value $Script:Context.SmtpHostPort         -NoAppend
Set-DockerVariable -Name SMTP_USERNAME          -Value $Script:Context.SmtpUserName         -NoAppend
Set-DockerVariable -Name SMTP_USERPASS          -Value (ConvertFrom-SecureString -SecureString $Script:Context.SmtpUserPass -AsPlainText) -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_HOSTNAME -Value $Script:Context.SmtpProviderHostname -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_PORT     -Value $Script:Context.SmtpProviderPort     -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_USERNAME -Value $Script:Context.SmtpProviderUserName -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_USERPASS -Value (ConvertFrom-SecureString -SecureString $Script:Context.SmtpProviderUserPass -AsPlainText) -NoAppend


## GET SERVICES INFORMATION ####################################################
Write-Information -Message ($Script:Context | Out-String)
$compose = Get-DockerCompose -Path $Script:Context.ComposeFile
$volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys
Set-DockerContext -Name Service -Value $volumes
Write-Information -Message ($Script:Context | Out-String)


## LOAD SUBMODULES SCRIPTS #####################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    foreach ($script in (Get-Item -Path (Join-Path -Path $Script:Context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))) {
        Write-Information -Message "Loading submodule script '$($script.FullName)'."
        . $script.FullName
    }
}

## SET STORAGE PERMISSION ######################################################
foreach ($service in $Script:Context.Service.Keys) {
    if ($Script:Context.Service.$service.Volume) {
        Write-Information -Message "Configuring storage for service $($service)"
        #Grant-DockerPermission `
        #    -Path $Script:Context.Service.$service.Volume `
        #    -PUID $Script:Context.Service.$service.PUID `
        #    -PGID $Script:Context.Service.$service.PGID `
        #    -Permission "0775" `
        #    -Recurse `
        #    -Force
        Grant-DockerPermission `
            -Path $Script:Context.Service.$service.Volume `
            -PUID $Script:Context.Service.$service.PUID `
            -PGID $Script:Context.Service.$service.PGID `
            -Permission "0775" `
            -Force
    }
}


Write-Information -Message "Loaded script '$PSCommandPath'."
