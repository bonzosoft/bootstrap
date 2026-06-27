function Get-DockerContext {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.OrderedHashtable])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FIleInfo]$Path
    )

    begin {
        [System.Management.Automation.OrderedHashtable]$context = [ordered]@{}
        [System.Management.Automation.OrderedHashtable]$tenantInfo = [ordered]@{}
    }

    process {
        $workingDir = [IO.DirectoryInfo]${PWD}.Path
        
        $context.ProjectName     = [string]$WorkingDir.BaseName
        $context.Hostname        = [string](Get-DockerHostname)
        # WorkingDir
        $context.WorkingDir      = [IO.DirectoryInfo]$workingDir
        #$context.ConfigDir       = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir -ChildPath @("config"))
        $context.IncludeDir      = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir -ChildPath @("include"))
        $context.MainDotEnvFile  =      [IO.FileInfo](Join-Path -Path $context.WorkingDir -ChildPath @(".env"))
        $context.MainComposeFile =      [IO.FileInfo](Join-Path -Path $context.WorkingDir -ChildPath @("compose.yaml"))
        # HostConfigFile        
        #$context.HostConfigFile  =      [IO.FileInfo](Join-Path -Path $context.WorkingDir.Parent -ChildPath @(".config", "host", "config.json"))
        $context.HostConfigFile  =      [IO.FileInfo]$Path
        # StateDir
        $context.StateDir        = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir.Parent.Parent -ChildPath @("state", $context.ProjectName))
        $context.SecretsDir      = [IO.DirectoryInfo](Join-Path -Path $context.StateDir   -ChildPath @(".secrets"))
        # LFStorage
        $context.LFStorageDir    = [IO.DirectoryInfo](Join-Path -Path $context.WorkingDir.Parent.Parent -ChildPath @("lfstorage", $context.ProjectName))
        # CommonDir
        $context.CommonDir       = [IO.DirectoryInfo]($MyInvocation.PSScriptRoot) #Write-Information (Get-PSCallStack | Format-Table Command, Location | Out-String)
        # Docker
        $context.Docker          =          [ordered]@{}
        $context.Docker.PUID     =              [int]568
        $context.Docker.PGID     =              [int]568
        $context.Docker.HostPGID =              [int](Get-DockerHostPGID)
        # Tenant
        $context.Tenant  = (Get-Content -Path $context.HostConfigFile | ConvertFrom-Json).Tenant
        if (-not $context.Tenant) {
            throw "Tenant name is mandatory."
        }
        $context.TenantsFile     =      [IO.FileInfo](Join-Path -Path $context.CommonDir -ChildPath @("tenants", "$($context.Tenant.ToLower()).json"))
        if (-not (Test-Path $context.TenantsFile)) {
            throw "Unknown tenant name."
        }
        
        $tenantInfo = Get-Content -Path $context.TenantsFile | ConvertFrom-Json -Depth 9 -AsHashTable
        foreach ($key in $tenantInfo.Keys) {
            if ( $tenantInfo.$key -ne "") {
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