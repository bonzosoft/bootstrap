function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Data
    )

    write-host "pasa"
    [IO.FileSystemInfo[]]$volumesList = @()

    foreach ($service in $Data.services.Keys) {
        write-host "pasa"

        $Data.services.$service
        if ($Data.services.$service.Keys -like "volumes") {
            foreach ($volume in $Data.services.$service.volumes.source) {
                write-host "pasa"

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