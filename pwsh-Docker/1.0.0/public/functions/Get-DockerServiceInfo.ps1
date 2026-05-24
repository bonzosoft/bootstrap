function Get-DockerServiceInfo {
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
        #[IO.FileSystemInfo[]]$volumes = @()
        [hashtable]$servicesTable = @{}
        [string]$volumePath = ""
    }

    process {
        foreach ($item in $Service) {
            $volumesList = @()
            foreach ($volume in $InputObject.services.$item.volumes) {
                switch ($InputObject.services.$item.$volume.type) {
                    "bind" {
                        $volumePath = $InputObject.services.$item.$volume.source
                    }
                    "volume" {
                        $volumePath = $InputObject.volumes.$volume.driver_opts.device
                    }
                    default {
                        continue
                    }
                }
                if ((-not $Force) -and (-not $volumePath.StartsWith($Script:Context.DataDir))) {
                    continue
                }
                Write-Host "volume: $volumePath"
                if (Test-Path -Path $volumePath) {
                    $volumesList += Get-Item -Path $volumePath
                }
                else {
                    $volumesList += [IO.DirectoryInfo]$volumePath
                }
            }
            $servicesTable[$item] = @{
                Volume = $volumesList
                PUID = [int]($InputObject.services.$item.user -split ":")[0]
                PGID = [int]($InputObject.services.$item.user -split ":")[1]
            }
        }
        Write-Output -InputObject $servicesTable
    }
}
