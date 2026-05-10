function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Data
    )

    begin {
        [IO.FileSystemInfo[]]$volumesList = @()
        [hashtable]$volumesObject = @{}
    }

    end {
        foreach ($service in $Data.services.Keys) {
            if ($Data.services.$service.Keys -like "volumes") {
                $volumesList = @()
                foreach ($volume in $Data.services.$service.volumes.source) {
                    if (-not $volume.StartsWith($Script:Context.DataDir)) {
                        Write-Warning -Message "System directory. Skipping."
                        continue
                    }
                    
                    if (Test-Path -Path $volume) {
                        $volumesList += Get-Item -Path $volume
                    }
                    else {
                        $volumesList += [IO.DirectoryInfo]$volume
                    }
                }
                $volumesObject[$service] = $volumesList
            }
        }
        Write-Output -InputObject ([PSCustomObject]$volumesObject)
    }
}