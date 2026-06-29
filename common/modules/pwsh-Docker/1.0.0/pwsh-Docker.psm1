[IO.FileInfo]$Self = $PSCommandPath


Write-Verbose -Message "Loading module '$($Self.BaseName)'."


### List of required modules ###################################################
[string[]]$requiredModules = @(
    "powershell-yaml"
    "pwsh-dotenv"
)


### List of requried binaries ##################################################
[string[]]$requiredBinaries = @(
    # nop
)


### Public variables ###########################################################
[System.Management.Automation.OrderedHashtable]$Script:Context = [ordered]@{}

# export public variables
Export-ModuleMember -Variable *


### Private variables ##########################################################
# nop


### Look for module assets #####################################################
# Get public function definition files
[IO.FileInfo[]]$publicFunctions = Get-ChildItem -Path (Join-Path -Path $Self.DirectoryName -ChildPath "public/functions/*.ps1") -Recurse -ErrorAction SilentlyContinue

# Get private function definition files
[IO.FileInfo[]]$privateFunctions = Get-ChildItem -Path (Join-Path -Path $Self.DirectoryName -ChildPath "private/functions/*.ps1") -Recurse -ErrorAction SilentlyContinue

# Get public classes definition files
[IO.FileInfo[]]$publicClasses = Get-ChildItem -Path (Join-Path -Path $Self.DirectoryName -ChildPath "public/classes/*.ps1") -Recurse -ErrorAction SilentlyContinue

# Get private classes definition files
[IO.FileInfo[]]$privateClasses = Get-ChildItem -Path (Join-Path -Path $Self.DirectoryName -ChildPath "private/classes/*.ps1") -Recurse -ErrorAction SilentlyContinue


### Load of module assets ######################################################
# Import required modules
foreach ($module in $requiredModules) {
    Write-Verbose -Message "Loading submodule '$module'."
    Import-Module -Name (Join-Path -Path $Self.DirectoryName -ChildPath "etc" -AdditionalChildPath $module) -Force
}

# Import required binaries
foreach ($binary in $requiredBinaries) {
    Write-Verbose -Message "Loading binary '$binary'."
    Add-Type -Path (Join-Path -Path $Self.DirectoryName -ChildPath "bin" -AdditionalChildPath $binary)
}

# Dot source function definition files
foreach ($function in ($publicFunctions + $privateFunctions)) {    
    Write-Verbose -Message "Loading function '$($function.BaseName)'."
    . $function.FullName
}

## Dot source classes definition files
foreach ($class in ($publicClasses + $privateClasses)) {
    Write-Verbose -Message "Loading function '$($class.BaseName)'."
    . $class.FullName
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


Write-Verbose -Message "Loaded module '$($Self.BaseName)'."
