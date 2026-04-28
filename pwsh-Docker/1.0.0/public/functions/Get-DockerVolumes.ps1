function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )

    write-host "pasa1"
    [IO.FileSystemInfo[]]$volumesList = @()

    foreach ($service in $Data.services.Keys) {
        write-host "pasa2"

        $Data.services.$service
        if ($Data.services.$service.Keys -like "volumes") {
            foreach ($volume in $Data.services.$service.volumes.source) {
                write-host "pasa3"

                if (Test-Path -Path $volume) {
                    $volumesList += Get-Item -Path $volume
                }
                else {
                    $volumesList += [IO.DirectoryInfo]$volume
                }
            }
        }
    }
    write-host "pasa4"
    
    return $volumesList
}