function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([Collections.Generic.List[IO.FileSystemInfo]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )
    [Collections.Generic.List[string]]$temporaryList = @()
    [Collections.Generic.List[IO.FileSystemInfo]]$volumesList = @()


    foreach ($service in $Data.services) {
        #Write-Host "Servicio: $($service.Keys)"
        foreach ($serviceName in $service.Keys ) {
            if ($service.$serviceName.Keys -contains "volumes") {
                #$service.$serviceName.volumes.source
                $temporaryList.AddRange([string[]]$service.$serviceName.volumes.source)
                #$volumesList.AddRange(($service.$serviceName.volumes.source) -split " ")
            }
        }
    }
    foreach ($item in $temporaryList) {
        if (Test-Path -Path $item) {
            $volumesList.Add((Get-Item -Path $item))
        }
        else {
            $volumesList.Add([IO.DirectoryInfo]$item)
        }
    }
    return $volumesList
}