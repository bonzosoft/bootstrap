#[CmdletBinding()]
#
#param(
#    [Parameter()]
#    [ValidateNotNullOrEmpty()]
#    [IO.DirectoryInfo]$Storage = "/mnt"
#)


Write-Host "Loading module '$PSCommandPath'."


### List of required modules ###################################################
[string[]] $requiredModules = @(
    "/PSModules/powershell-yaml"
    #"/PSModules/pwsh-dotenv"
)


### Public variables ###########################################################
[IO.DirectoryInfo]$Script:WORKINGDIR = (Get-Location).Path

# project information
[string]$Script:PROJECTNAME          = $Script:WORKINGDIR.BaseName
[int]$Script:PUID                    = 568
[int]$Script:PGID                    = 568
[int]$Script:DOCKER_GID              = (Get-Content ./mnt/tank0/apps/config.json | ConvertFrom-Json).DOCKER_GID
# project directory structure
[IO.DirectoryInfo]$Script:CONFIGDIR   = Join-Path -Path $Script:WORKINGDIR -ChildPath "config"
[IO.DirectoryInfo]$Script:INCLUDEDIR  = Join-Path -Path $Script:WORKINGDIR -ChildPath "include"
[IO.FileInfo]$Script:COMPOSEFILE      = Join-Path -Path $Script:WORKINGDIR -ChildPath "compose.yaml"
[IO.FileInfo]$Script:ENVFILE          = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env"

# data directory structure
[IO.DirectoryInfo]$Script:DATADIR     = Join-Path -Path $Script:WORKINGDIR.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:PROJECTNAME
[IO.DirectoryInfo]$Script:SECRETSDIR  = Join-Path -Path $Script:DATADIR -ChildPath ".secrets"

# infra directory structure
[IO.FileInfo]$Script:CONFIGJSON       = Join-Path -Path $Script:WORKINGDIR.Parent -ChildPath "config.json"
Export-ModuleMember -Variable *


### Private variables ##########################################################
# nop


### Look for module assets #####################################################

# Get public function definition files
[Collections.Generic.List[IO.FileInfo]]$publicFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "public/functions/*.ps1") -ErrorAction SilentlyContinue

# Get private function definition files
[Collections.Generic.List[IO.FileInfo]]$privateFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "private/functions/*.ps1") -ErrorAction SilentlyContinue

# Get public classes definition files
[Collections.Generic.List[IO.FileInfo]]$publicClasses = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "public/classes/*.ps1") -ErrorAction SilentlyContinue

# Get private classes definition files
[Collections.Generic.List[IO.FileInfo]]$privateClasses = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "private/classes/*.ps1") -ErrorAction SilentlyContinue


### Load of module assets ######################################################

# Import required modules
Import-Module -Name $requiredModules -Force

# Dot source function definition files
foreach ($function in @($publicFunctions + $privateFunctions)) {    
    if ($null -ne $function) {
        Write-Host "Sourcing function '$($function.BaseName)'."
        . $function.FullName
    }
}

## Dot source classes definition files
foreach ($class in @($publicClasses + $privateClasses)) {
    if ($null -ne $class) {
        Write-Host "Sourcing function '$($class.BaseName)'."
        . $class.FullName
    }
}


### Export public module assets ################################################

# Export public function definition files
foreach ($function in $publicFunctions) {
    Export-ModuleMember -Function $function.BaseName
}

# Export public class type accelerators
foreach ($class in $PublicClasses) {
    [Type]$type = [Type]$class.BaseName
    [PSObject]$typeAccelerator = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")
    $typeAccelerator::Remove($type.FullName)
    $typeAccelerator::Add($type.FullName, $type)
    $MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {$typeAccelerator::Remove($type.FullName)} | Out-Null
}


Write-Host "Finishing module '$PSCommandPath'."
