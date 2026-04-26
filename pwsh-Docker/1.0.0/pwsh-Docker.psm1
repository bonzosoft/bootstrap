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
