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


## PULL SUBMODULES #############################################################
if (Test-Path -Path $Script:Context.IncludeDir) {
    Write-Information -Message "Pulling submodules."
    $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
    if ($LASTEXITCODE) {
        throw ($errorVariable | Out-String)
    }
}


## SET ENV FILE VARIABLES ######################################################
Get-Content -Path $Script:Context.DotEnvFile | ForEach-Object {
    $string = $PSItem
    if (-not ($string.Trim() -like "^#")) {
        $string = $string.Replace('[[SERVERNAME]]',    $Script:Context.Hostname)
        $string = $string.Replace('[[DATADIR]]',            $Script:Context.DataDir.FullName)
        $string = $string.Replace('[[DOMAIN]]',             $Script:Context.Domain)
        $string = $string.Replace('[[PROJECTNAME]]',        $Script:Context.Docker.ProjectName)
        $string = $string.Replace('[[PUID]]',               $Script:Context.Docker.PUID)
        $string = $string.Replace('[[PGID]]',               $Script:Context.Docker.PGID)
        $string = $string.Replace('[[SOCKETPROXY_PGID]]',   $Script:Context.Docker.DockerPGID)
        $string = $string.Replace('[[ADMIN_USER]]',         $Script:Context.Admin.username)
        $string = $string.Replace('[[ADMIN_PASS]]',         $Script:Context.Admin.userpass)
        $string = $string.Replace('[[ADMIN_EMAIL]]',        $Script:Context.Admin.email)
        $string = $string.Replace('[[SMTP_RELAY_HOST]]',    $Script:Context.Smtp.relay.hostname)
        $string = $string.Replace('[[SMTP_RELAY_PORT]]',    $Script:Context.Smtp.relay.port)
        $string = $string.Replace('[[SMTP_RELAY_USER]]',    $Script:Context.Smtp.relay.username)
        $string = $string.Replace('[[SMTP_RELAY_PASS]]',    $Script:Context.Smtp.relay.userpass)
        $string = $string.Replace('[[SMTP_PROVIDER_HOST]]', $Script:Context.Smtp.provider.hostname)
        $string = $string.Replace('[[SMTP_PROVIDER_PORT]]', $Script:Context.Smtp.provider.port)
        $string = $string.Replace('[[SMTP_PROVIDER_USER]]', $Script:Context.Smtp.provider.username)
        $string = $string.Replace('[[SMTP_PROVIDER_PASS]]', $Script:Context.Smtp.provider.userpass)
    }
    Write-Output -InputObject $string
} | Set-Content -Path "$($Script:Context.DotEnvFile).tmp"
Move-Item -Path "$($Script:Context.DotEnvFile).tmp" -Destination $Script:Context.DotEnvFile -Force
Write-Verbose -Message ($Script:Context | Out-String)


## GET SERVICES INFORMATION ####################################################
$compose = Get-DockerCompose -Path $Script:Context.ComposeFile
$volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys -Verbose
$Script:Context += @{
    "Service"= $volumes
}
Write-Verbose -Message ($Script:Context | Out-String)


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
