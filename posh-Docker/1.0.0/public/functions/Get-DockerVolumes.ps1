function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )

    [IO.FileSystemInfo[]]$volumesList = @()

    foreach ($service in $Data.services.Keys) {
        #Write-Host "Servicio: $($service.Keys)"
        if ($service.Keys -contains "volumes") {
            foreach ($volume in $service.volumes.source) {
                if (Test-Path -Path $volume) {
                    $volumesList += Get-Item -Path $volume
                }
                else {
                    $volumesList += [IO.DirectoryInfo]$volume
                }
            }
        }
    }
    
    return $volumesList
}