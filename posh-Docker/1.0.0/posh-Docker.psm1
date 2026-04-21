[CmdletBinding()]

param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]$RootPath 
)


Write-Host "Loading $PSCommandPath"


### List of required modules ###################################################
[string[]] $requiredModules = @(
    "/PSModules/powershell-yaml"
    #"/PSModules/pwsh-dotenv"
)


### Public variables ###########################################################
[IO.FileInfo]$Script:ENTRYSCRIPT      = $RootPath
[IO.DirectoryInfo]$Script:WORKINGDIR  = $Script:ENTRYSCRIPT.Directory
[IO.DirectoryInfo]$Script:INCLUDEDIR  = Join-Path -Path $Script:WORKINGDIR -ChildPath "include"
[IO.DirectoryInfo]$Script:CONFIGDIR   = Join-Path -Path $Script:WORKINGDIR -ChildPath "config"
[IO.FileInfo]$Script:ENVFILE          = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env"
[IO.FileInfo]$Script:COMPOSEFILE      = Join-Path -Path $Script:WORKINGDIR -ChildPath "compose.yaml"
[IO.DirectoryInfo]$Script:COMMONDIR   = $PSScriptRoot
[IO.FileInfo]$Script:COMMONENVFILE    = Join-Path -Path $Script:COMMONDIR -ChildPath ".env.common"
[IO.FileInfo]$Script:COMMONCONFIGFILE = Join-Path -Path $Script:COMMONDIR -ChildPath "../config.json"
[int]$Script:PUID = 568
[int]$Script:PGID = 568
[IO.DirectoryInfo]$Script:DATADIR     = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath "state"
[IO.DirectoryInfo]$Script:SECRETSDIR  = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath ".secrets"
Export-ModuleMember -Variable *


### Private variables ##########################################################


### Look for module assets #####################################################

# Get public function definition files
[IO.FileInfo[]]$publicFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "public/functions/*.ps1") -ErrorAction SilentlyContinue

# Get private function definition files
[IO.FileInfo[]]$privateFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "private/functions/*.ps1") -ErrorAction SilentlyContinue

# Get public classes definition files
[IO.FileInfo[]]$publicClasses = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "public/classes/*.ps1") -ErrorAction SilentlyContinue

# Get private classes definition files
[IO.FileInfo[]]$privateClasses = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "private/classes/*.ps1") -ErrorAction SilentlyContinue


### Load of module assets ######################################################

# Import required modules
Import-Module -Name $requiredModules -Force

# Dot source function definition files
foreach ($function in @($publicFunctions + $privateFunctions)) {
    . $function.FullName
}

## Dot source classes definition files
#foreach ($class in @($publicClasses + $privateClasses)) {
#    . $class.FullName
#}


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


Write-Host "Finishing $PSCommandPath"
