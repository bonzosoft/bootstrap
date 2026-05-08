function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Data
    )

    begin {
        [IO.FileSystemInfo[]]$volumesList = @()
    }

    end {
        foreach ($service in $Data.services.Keys) {
            if ($Data.services.$service.Keys -like "volumes") {
                foreach ($volume in $Data.services.$service.volumes.source) {
                    if (-not ($($item.FullName).StartsWith($Script:Context.DataDir))) {
                        Write-Host "System directory. Skipping."
                        continue
                    }
                    
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
}