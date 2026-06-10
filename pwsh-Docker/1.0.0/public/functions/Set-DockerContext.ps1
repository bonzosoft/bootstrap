function Set-DockerContext {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.OrderedHashtable])]

    param(

    )

    begin {
        [hashtable]$context = [ordered]@{}
    }

    process {
        $workingDir = [IO.DirectoryInfo](Get-Location).Path

        $context.ProjectName     =           [string]$WorkingDir.BaseName
        $context.Hostname        =           [string](Get-DockerHostname)
        # WorkingDir
        $context.WorkingDir      = [IO.DirectoryInfo]$workingDir
        $context.ConfigDir       = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir               -ChildPath "" -AdditionalChildPath @("config"))
        $context.IncludeDir      = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir               -ChildPath "" -AdditionalChildPath @("include"))
        $context.MainDotEnvFile  =      [IO.FileInfo](Join-Path -Path $context.WorkingDir               -ChildPath "" -AdditionalChildPath @(".env"))
        $context.MainComposeFile =      [IO.FileInfo](Join-Path -Path $context.WorkingDir               -ChildPath "" -AdditionalChildPath @("compose.yaml"))
        # HostConfigFile        
        $context.HostConfigFile  =      [IO.FileInfo](Join-Path -Path $context.WorkingDir.Parent        -ChildPath "" -AdditionalChildPath @(".config", "host", "config.json"))
        # StateDir
        $context.StateDir        = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $context.ProjectName))
        $context.SecretsDir      = [IO.DirectoryInfo](Join-Path -Path $context.StateDir                 -ChildPath "" -AdditionalChildPath @(".secrets"))
        # CommonDir
        $context.CommonDir       = [IO.DirectoryInfo]($PSScriptRoot)  # ([IO.FileInfo]$PSCommandPath).Directory
        # Docker
        [hashtable]$hash = [ordered]@{
            "PUID"     = [int]568
            "PGID"     = [int]568
            "HostPGID" = [int](Get-DockerHostPGID)
        }
        $context.Docker += $hash
        #$context.Docker.PUID     = [int]568
        #$context.Docker.PGID     = [int]568
        #$context.Docker.HostPGID = [int](Get-DockerHostPGID)
        
        $context | Out-String
        
        # Tenant
        $context.Tenant.Name     = (Get-Content -Path $context.HostConfigFile | ConvertFrom-Json).Tenant
        $context.TenantsDir      = [IO.DirectoryInfo](Join-Path -Path $context.CommonDir                -ChildPath "" -AdditionalChildPath @("tenants"))       
        $context.TenantsFile     =      [IO.FileInfo](Join-Path -Path $context.TenantsDir               -ChildPath "" -AdditionalChildPath @("$tenantName.json"))
        $content = [hashtable](Get-Content -Path $tenantFile | ConvertFrom-Json -Depth 9 -AsHashtable)
        $context.Admin.Name = $content.Admin.Name 
        #$context.Admin.Password         = ConvertTo-SecureString -String $context.Admin.Password -AsPlainText
        #$context.Smtp.Relay.Password    = ConvertTo-SecureString -String $context.Smtp.Relay.Password -AsPlainText
        #$context.Smtp.Provider.Password = ConvertTo-SecureString -String $context.Smtp.Provider.Password -AsPlainText

        # StorageDir
        #if ($context.LfsStorageDir -eq "") {
        #    $context.LfsStorageDir = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("storage", $context.ProjectName))
        #}
        
        
    }

    end {
        $Script:Context = $context
        Write-Ouput $Script:Context
    }
}