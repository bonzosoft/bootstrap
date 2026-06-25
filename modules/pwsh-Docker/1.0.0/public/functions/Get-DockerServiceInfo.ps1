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
            Write-Information "Checking service '$item' for volumes."

            $volumesList = @()
            
            foreach ($volume in $InputObject.services.$item.volumes) {
                Write-Information "Checking volume '$($volume.source)'. Type is $($volume.type)"

                switch ($volume.type) {
                    "bind" {
                        $volumePath = $volume.source
                    }
                    "volume" {
                        $volumePath = Join-Path -Path $InputObject.volumes.$($volume.source).driver_opts.device -ChildPath $volume.volume.subpath
                    }
                    default {
                        continue
                    }
                }
                if ( (-not $Force) `
                    -and (-not $volumePath.StartsWith($Script:Context.DataDir.FullName)) `
                    -and (-not $volumePath.StartsWith($Script:Context.StateDir.FullName)) `
                    -and (-not $volumePath.StartsWith($Script:Context.LFStorageDir.FullName)) `
                    ) {
                    Write-Information "Skipping system volume."
                    continue
                }
                Write-Information "Adding volume path: '$volumePath'."
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
