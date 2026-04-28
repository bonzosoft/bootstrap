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
        $Data.services.$service
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
    write-host "pasa"
    Write-HOst $volumesList.GetTYpe()
    return [IO.FileSystemInfo[]]$volumesList
}