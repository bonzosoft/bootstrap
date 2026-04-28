function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Data
    )

    [IO.FileSystemInfo[]]$volumesList = @()

    foreach ($service in $Data.services.Keys) {
        if ($Data.services.$service.Keys -like "volumes") {
            foreach ($volume in $Data.services.$service.volumes.source) {
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