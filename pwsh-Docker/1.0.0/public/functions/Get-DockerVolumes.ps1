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
                $volumesList = @()
                foreach ($volume in $InputObject.services.$item.volumes.source) {
                    if ((-not $Force) -and (-not $volume.StartsWith($Script:Context.DataDir))) {
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
                    $volumesTable[$item] = @{
                        volumes = $volumesList
                        user = 568
                        group = 568
                    }
                    #$volumesTable[$item]["volumes"] = $volumesList
                    #$volumesTable[$item]["user"] = 568
                    #$volumesTable[$item]["group"] = 568
                }
            }
        }
        Write-Output -InputObject $volumesTable
    }
}
