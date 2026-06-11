function Get-DockerContext {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.OrderedHashtable])]

    param(

    )

    begin {
        [System.Management.Automation.OrderedHashtable]$context = [ordered]@{}
        [System.Management.Automation.OrderedHashtable]$tenantInfo = [ordered]@{}
    }

    process {
        $workingDir = [IO.DirectoryInfo](Get-Location).Path
        
        $context.ProjectName     = [string]$WorkingDir.BaseName
        $context.Hostname        = [string](Get-DockerHostname)
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
        # LFStorage
        $context.LFStorage       = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("lfstorage", $context.ProjectName))
        # CommonDir
        $context.CommonDir       = [IO.DirectoryInfo]($MyInvocation.PSScriptRoot) #Write-Information (Get-PSCallStack | Format-Table Command, Location | Out-String)
        # Docker
        $context.Docker          =          [ordered]@{}
        $context.Docker.PUID     =              [int]568
        $context.Docker.PGID     =              [int]568
        $context.Docker.HostPGID =              [int](Get-DockerHostPGID)
        # Tenant
        $context.TenantsDir      = [IO.DirectoryInfo](Join-Path -Path $context.CommonDir                -ChildPath "" -AdditionalChildPath @("tenants"))       
        $context.TenantsFile     =      [IO.FileInfo](Join-Path -Path $context.TenantsDir               -ChildPath "" -AdditionalChildPath @("$((Get-Content -Path $context.HostConfigFile | ConvertFrom-Json).Tenant).json"))
        $context.Tenant          =           [string]($context.TenantsFile.BaseName)
        
        $tenantInfo = Get-Content -Path $context.TenantsFile | ConvertFrom-Json -Depth 9 -AsHashTable
        foreach ($key in $tenantInfo.Keys) {
            if (-not ($tenantInfo.$key -eq "")){
                $context.$key = $tenantInfo.$key
            }
        }
        # To be replaced by sops
        $context.Admin.Password         = ConvertTo-SecureString -String $context.Admin.Password -AsPlainText
        $context.Smtp.Relay.Password    = ConvertTo-SecureString -String $context.Smtp.Relay.Password -AsPlainText
        $context.Smtp.Provider.Password = ConvertTo-SecureString -String $context.Smtp.Provider.Password -AsPlainText
    }

    end {
        $Script:Context = $context
        Write-Output $Script:Context
    }
}