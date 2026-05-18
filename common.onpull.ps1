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
if (Test-Path -Path $Script:Context.Path.IncludeDir) {
    Write-Information -Message "Pulling submodules."
    $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
    if ($LASTEXITCODE) {
        throw ($errorVariable | Out-String)
    }
}


## SET ENV FILE VARIABLES
Set-DockerVariable -Name DATADIR                -Value $Script:Context.Path.DataDir.FullName
Set-DockerVariable -Name PUID                   -Value $Script:Context.Docker.PUID
Set-DockerVariable -Name PGID                   -Value $Script:Context.Docker.PGID
Set-DockerVariable -Name SOCKETPROXY_PGID       -Value $Script:Context.Docker.DockerPGID     -NoAppend
Set-DockerVariable -Name DOMAIN                 -Value $Script:Context.Domain                -NoAppend
Set-DockerVariable -Name SMTP_HOSTNAME          -Value $Script:Context.SMTP.Hostname         -NoAppend
Set-DockerVariable -Name SMTP_HOSTPORT          -Value $Script:Context.SMTP.Port             -NoAppend
Set-DockerVariable -Name SMTP_USERNAME          -Value $Script:Context.SMTP.UserName         -NoAppend
Set-DockerVariable -Name SMTP_USERPASS          -Value $Script:Context.SMTP.UserPass -NoAppend #(ConvertFrom-SecureString -SecureString $Script:Context.SMTP.UserPass -AsPlainText) -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_HOSTNAME -Value $Script:Context.ProviderSMTP.Hostname -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_PORT     -Value $Script:Context.ProviderSMTP.Port     -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_USERNAME -Value $Script:Context.ProviderSMTP.UserName -NoAppend
Set-DockerVariable -Name SMTP_PROVIDER_USERPASS -Value $Script:Context.ProviderSMTP.UserPass -NoAppend #(ConvertFrom-SecureString -SecureString $Script:Context.SmtpProviderUserPass -AsPlainText) -NoAppend


## GET SERVICES INFORMATION ####################################################
Write-Information -Message ($Script:Context | Out-String)
$compose = Get-DockerCompose -Path $Script:Context.Path.ComposeFile
$volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys
#Set-DockerContext -Name Service -Value $volumes
$Script:Context += @{
    "service"= $volumes
}
Write-Information -Message ($Script:Context | Out-String)


## LOAD SUBMODULES SCRIPTS #####################################################
if (Test-Path -Path $Script:Context.Path.IncludeDir) {
    foreach ($script in (Get-Item -Path (Join-Path -Path $Script:Context.Path.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))) {
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
