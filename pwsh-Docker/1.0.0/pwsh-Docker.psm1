Write-Host "Importing module '$PSCommandPath'."


### List of required modules ###################################################
[string[]] $requiredModules = @(
    "powershell-yaml"
    "pwsh-dotenv"
)


### Public variables ###########################################################
# nop


# export public variables
Export-ModuleMember -Variable *


### Private variables ##########################################################
[PSCustomObject]$Script:Env = [PSCustomObject]@{}
$Script:Env | Add-Member -MemberType NoteProperty -Name WorkingDir       -Value ([IO.DirectoryInfo](Get-Location).Path)
$Script:Env | Add-Member -MemberType NoteProperty -Name ProjectName      -Value ([string]$Script:Env.WorkingDir.BaseName)
$Script:Env | Add-Member -MemberType NoteProperty -Name ConfigDir        -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Env.WorkingDir -ChildPath "config"))
$Script:Env | Add-Member -MemberType NoteProperty -Name IncludeDir       -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Env.WorkingDir -ChildPath "include"))
$Script:Env | Add-Member -MemberType NoteProperty -Name ComposeFile      -Value ([IO.FileInfo](Join-Path -Path $Script:Env.WorkingDir -ChildPath "compose.yaml"))
$Script:Env | Add-Member -MemberType NoteProperty -Name DotEnvFile       -Value ([IO.FileInfo](Join-Path -Path $Script:Env.WorkingDir -ChildPath ".env"))
$Script:Env | Add-Member -MemberType NoteProperty -Name DataDir          -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Env.WorkingDir.Parent.Parent -ChildPath "state" -AdditionalChildPath $Script:Env.ProjectName))
$Script:Env | Add-Member -MemberType NoteProperty -Name SecretsDir       -Value ([IO.DirectoryInfo](Join-Path -Path $Script:Env.DataDir -ChildPath ".secrets"))
$Script:Env | Add-Member -MemberType NoteProperty -Name GlobalConfigFile -Value ([IO.FileInfo](Join-Path -Path $Script:Env.WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json"))
$Script:Env | Add-Member -MemberType NoteProperty -Name PUID             -Value ([int]568)
$Script:Env | Add-Member -MemberType NoteProperty -Name PGID             -Value ([int]568)
$Script:Env | Add-Member -MemberType NoteProperty -Name DOCKER_PGID      -Value ([int]$config.DOCKER_PGID)

if (Test-Path -Path $Script:Env.GlobalConfigFile) {
    $config = Get-Content -Path $Script:Env.GlobalConfigFile | ConvertFrom-Json
}
else {
    throw "File '$($Script:Env.EnvFile)' not found."
}

Write-Host "WorkingDir:`t$($Script:Env.WorkingDir)"
Write-Host "DataDir:`t$($Script:Env.DataDir)"

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
foreach ($module in $requiredModules) {
    Write-Host "Importing submodule $module."
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "modules" -AdditionalChildPath $module) -Force
}

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


Write-Host "Imported module '$PSCommandPath'."
