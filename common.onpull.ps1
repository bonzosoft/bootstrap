#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param(
    
)

begin {
    # ==========================================================================
    # SINGLETON
    # ==========================================================================
    New-Variable -Name "singleton" -Scope Global -Value ("__INCLUDED_$(([IO.FileInfo]$PSCommandPath).Name.Replace(".","_").ToUpper())__")
    if (Get-Variable -Name $singleton -Scope Global -ErrorAction SilentlyContinue) {
        Write-Information -MessageData "Script '$PSCommandPath' already loaded. Skipping."
        return
    }
    else {
        Write-Information -MessageData "Loading script '$PSCommandPath'."
        New-Variable -Name $singleton -Scope Global -Value $true
    }
    Remove-Variable -Name "singleton"
}

process {
    # ==========================================================================
    # LOAD COMMON ASSETS
    # ==========================================================================
    . (Join-Path -Path ([IO.FileInfo]$PSCommandPath).Directory -ChildPath @("common.ps1"))
    

    # ==========================================================================
    # PULL SUBMODULES
    # ==========================================================================
    if (Test-Path -Path $Script:context.IncludeDir) {
        Assert-GitProviderSession -Provider $gitProvider
        Write-Information -MessageData "Pulling git submodules."
        $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
        if ($LASTEXITCODE) {
            throw ($errorVariable | Out-String)
        }
    }
    
    
    ## SET ENV FILE VARIABLES ######################################################
    Get-Content -Path $Script:context.MainDotEnvFile -Encoding utf8 |
    ForEach-Object { Expand-DockerVariable -Content $PSItem } | 
    Set-Content -Path "$($Script:context.MainDotEnvFile).tmp" -Encoding utf8
    Move-Item -Path "$($Script:context.MainDotEnvFile).tmp" -Destination $Script:context.MainDotEnvFile -Force
    
    
    ## GET SERVICES INFORMATION ####################################################
    $compose = Get-DockerCompose -Path $Script:context.MainComposeFile
    $volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys -Verbose
    $Script:context += @{
        "Service"= $volumes
    }
    Write-Verbose -Message ($Script:context | Out-String)
    
    
    ## LOAD SUBMODULES SCRIPTS #####################################################
    #if (Test-Path -Path $Script:context.IncludeDir) {
    #    foreach ($script in (Get-Item -Path (Join-Path -Path $Script:context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))) {
    #        Write-Information -MessageData "Loading submodule script '$($script.FullName)'."
    #        . $script.FullName
    #    }
    #}
    
    
    ## SET STORAGE PERMISSION ######################################################
    foreach ($service in $Script:context.Service.Keys) {
        if ($Script:context.Service.$service.Volume) {
            Write-Information -MessageData "Configuring storage for service $($service)"
            Grant-DockerPermission `
                -Path $Script:context.Service.$service.Volume `
                -PUID $Script:context.Service.$service.PUID `
                -PGID $Script:context.Service.$service.PGID `
                -Permission "0775" `
                -Force
        }
    }
}

end {
    Write-Information -MessageData "Completed script '$PSCommandPath'."
}
