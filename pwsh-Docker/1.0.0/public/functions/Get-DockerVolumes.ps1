function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$InputObject,

        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = $InputObject.services.Keys,

        [Parameter(ValueFromPipeline)]
        [switch]$Force
    )

    begin {
        [IO.FileSystemInfo[]]$volumesList = @()
        [hashtable]$volumesTable = @{}
    }

    process {
        foreach ($item in $Service) {
            if ($InputObject.services.$item.Keys -like "volumes") {
                foreach ($volume in $InputObject.services.$item.volumes.source) {
                    $volumesList = @()
                    if ((-not $Force) -and (-not $volume.StartsWith($Script:Context.InputObjectDir))) {
                        continue
                    }
                    if (Test-Path -Path $volume) {
                        $volumesList += Get-Item -Path $volume
                    }
                    else {
                        $volumesList += [IO.DirectoryInfo]$volume
                    }
                }
                if ($volumesList.Count) {
                    $volumesTable[$item] = $volumesList
                }
            }
        }
        Write-Host $volumesTable
        Write-Output -InputObject $volumesTable
    }
}
