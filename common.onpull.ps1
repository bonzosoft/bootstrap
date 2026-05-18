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
#Switch-DockerTenant


## PULL SUBMODULES #############################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    Write-Information -Message "Pulling submodules."
    $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
    if ($LASTEXITCODE) {
        throw ($errorVariable | Out-String)
    }
}


## SET ENV FILE VARIABLES ######################################################
#Set-DockerVariable -Name DATADIR                -Value $Script:Context.DataDir.FullName
#Set-DockerVariable -Name PUID                   -Value $Script:Context.Docker.PUID
#Set-DockerVariable -Name PGID                   -Value $Script:Context.Docker.PGID
#Set-DockerVariable -Name SOCKETPROXY_PGID       -Value $Script:Context.Docker.DockerPGID      -NoAppend
#Set-DockerVariable -Name DOMAIN                 -Value $Script:Context.Domain                 -NoAppend
#Set-DockerVariable -Name ADMIN_USERNAME         -Value $Script:Context.admin.username         -NoAppend
#Set-DockerVariable -Name ADMIN_USERP            -Value $Script:Context.admin.userpass         -NoAppend 
#Set-DockerVariable -Name ADMIN_EMAIL            -Value $Script:Context.admin.email            -NoAppend 
#Set-DockerVariable -Name SMTP_RELAY_HOSTNAME    -Value $Script:Context.smtp.relay.hostname    -NoAppend
#Set-DockerVariable -Name SMTP_RELAY_HOSTPORT    -Value $Script:Context.smtp.relay.port        -NoAppend
#Set-DockerVariable -Name SMTP_RELAY_USERNAME    -Value $Script:Context.smtp.relay.username    -NoAppend
#Set-DockerVariable -Name SMTP_RELAY_USERPASS    -Value $Script:Context.smtp.relay.userpass    -NoAppend #(ConvertFrom-SecureString -SecureString $Script:Context.SMTP.UserPass -AsPlainText) -NoAppend
#Set-DockerVariable -Name SMTP_PROVIDER_HOSTNAME -Value $Script:Context.smtp.provider.hostname -NoAppend
#Set-DockerVariable -Name SMTP_PROVIDER_PORT     -Value $Script:Context.smtp.provider.port     -NoAppend
#Set-DockerVariable -Name SMTP_PROVIDER_USERNAME -Value $Script:Context.smtp.provider.username -NoAppend
#Set-DockerVariable -Name SMTP_PROVIDER_USERPASS -Value $Script:Context.smtp.provider.userpass -NoAppend #(ConvertFrom-SecureString -SecureString $Script:Context.SmtpProviderUserPass -AsPlainText) -NoAppend

Get-Content -Path $Script:Context.DotEnvFile | ForEach-Object {
    $PSItem.Replace('[[DATADIR]]', $Script:Context.DataDir.FullName)
    $PSItem.Replace('[[DOMAIN]]', $Script:Context.Domain)
    $PSItem.Replace('[[PUID]]', $Script:Context.Docker.PUID)
    $PSItem.Replace('[[PGID]]', $Script:Context.Docker.PGID)
    $PSItem.Replace('[[SOCKETPROXY_PGID]]', $Script:Context.Docker.DockerPGID)
    $PSItem.Replace('[[ADMIN_USERNAME]]', $Script:Context.admin.username)
    $PSItem.Replace('[[ADMIN_USERPASS]]', $Script:Context.admin.userpass)
    $PSItem.Replace('[[ADMIN_EMAIL]]', $Script:Context.admin.email)
    $PSItem.Replace('[[SMTP_RELAY_HOST]]', $Script:Context.smtp.relay.hostname)
    $PSItem.Replace('[[SMTP_RELAY_PORT]]', $Script:Context.smtp.relay.port)
    $PSItem.Replace('[[SMTP_RELAY_USER]]', $Script:Context.smtp.relay.username)
    $PSItem.Replace('[[SMTP_RELAY_PASS]]', $Script:Context.smtp.relay.userpass)
    $PSItem.Replace('[[SMTP_PROVIDER_HOST]]', $Script:Context.smtp.provider.hostname)
    $PSItem.Replace('[[SMTP_PROVIDER_PORT]]', $Script:Context.smtp.provider.port)
    $PSItem.Replace('[[SMTP_PROVIDER_USER]]', $Script:Context.smtp.provider.username)
    $PSItem.Replace('[[SMTP_PROVIDER_PASS]]', $Script:Context.smtp.provider.userpass)

} | Set-Content -Path "$($Script:Context.DotEnvFile).tmp"
Move-Item -Path "$($Script:Context.DotEnvFile).tmp" -Destination $Script:Context.DotEnvFile -Force


## GET SERVICES INFORMATION ####################################################
Write-Information -Message ($Script:Context | Out-String)
$compose = Get-DockerCompose -Path $Script:Context.ComposeFile
$volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys
$Script:Context += @{
    "Service"= $volumes
}
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
        Grant-DockerPermission `
            -Path $Script:Context.Service.$service.Volume `
            -PUID $Script:Context.Service.$service.PUID `
            -PGID $Script:Context.Service.$service.PGID `
            -Permission "0775" `
            -Force
    }
}


Write-Information -Message "Loaded script '$PSCommandPath'."
