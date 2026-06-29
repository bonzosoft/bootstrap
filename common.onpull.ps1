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
    Remove-Variable -Name $singleton
}

process {
    # ==========================================================================
    # LOAD COMMON ASSETS
    # ==========================================================================
    . (Join-Path -Path ([IO.FileInfo]$PSCommandPath).Directory -ChildPath @("common.ps1"))
    

    # ==========================================================================
    # PULL SUBMODULES
    # ==========================================================================
    if (Test-Path -Path $Script:Context.IncludeDir) {
        Assert-GitProviderSession -Provider $gitProvider
        Write-Information -MessageData "Pulling submodules."
        $null = git submodule update --init --recursive --depth 1 2> variable:errorVariable
        if ($LASTEXITCODE) {
            throw ($errorVariable | Out-String)
        }
    }
    
    
    ## SET ENV FILE VARIABLES ######################################################
    Get-Content -Path $Script:Context.MainDotEnvFile -Encoding utf8 |
    ForEach-Object { Expand-DockerVariable -Content $PSItem } | 
    Set-Content -Path "$($Script:Context.MainDotEnvFile).tmp" -Encoding utf8
    Move-Item -Path "$($Script:Context.MainDotEnvFile).tmp" -Destination $Script:Context.MainDotEnvFile -Force
    #Write-Verbose -Message ($Script:Context | Out-String)
    
    
    ## GET SERVICES INFORMATION ####################################################
    $compose = Get-DockerCompose -Path $Script:Context.MainComposeFile
    $volumes = Get-DockerServiceInfo -InputObject $compose -Service $compose.services.Keys -Verbose
    $Script:Context += @{
        "Service"= $volumes
    }
    Write-Verbose -Message ($Script:Context | Out-String)
    
    
    ## LOAD SUBMODULES SCRIPTS #####################################################
    #if (Test-Path -Path $Script:Context.IncludeDir) {
    #    foreach ($script in (Get-Item -Path (Join-Path -Path $Script:Context.IncludeDir -ChildPath "*" -AdditionalChildPath (Split-Path -Path $MyInvocation.PSCommandPath -Leaf)))) {
    #        Write-Information -MessageData "Loading submodule script '$($script.FullName)'."
    #        . $script.FullName
    #    }
    #}
    
    
    ## SET STORAGE PERMISSION ######################################################
    foreach ($service in $Script:Context.Service.Keys) {
        if ($Script:Context.Service.$service.Volume) {
            Write-Information -MessageData "Configuring storage for service $($service)"
            Grant-DockerPermission `
                -Path $Script:Context.Service.$service.Volume `
                -PUID $Script:Context.Service.$service.PUID `
                -PGID $Script:Context.Service.$service.PGID `
                -Permission "0775" `
                -Force
        }
    }
}

end {
    Write-Information -MessageData "Completed script '$PSCommandPath'."
}
