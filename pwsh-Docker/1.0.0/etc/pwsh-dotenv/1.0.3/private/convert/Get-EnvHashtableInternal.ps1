#requires -Version 5
Set-StrictMode -Version Latest

function Get-EnvHashtableInternal() {
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    Param ()

    $envs = New-HashTbaleInternal
    foreach ($entry in (Get-ChildItem "${script:EnvDriveName}:")) {
        $envs[$entry.Name] = $entry.Value
    }
    return $envs
}
