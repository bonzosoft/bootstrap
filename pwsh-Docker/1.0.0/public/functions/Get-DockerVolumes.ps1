function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$InputObject,

        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = $InputObject.services.Keys
    )

    begin {
        [IO.FileSystemInfo[]]$volumesList = @()
        [hashtable]$volumesObject = @{}

    }

    process {
        foreach ($item in $Service) {
            Write-Host $item
        }
        
    }

    end {
        
        foreach ($item in $InputObject.services.Keys) {
            if ($InputObject.services.$item.Keys -like "volumes") {
                $volumesList = @()
                foreach ($volume in $InputObject.services.$item.volumes.source) {
                    if (-not $volume.StartsWith($Script:Context.InputObjectDir)) {
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
                    $volumesObject[$item] = $volumesList
                }
                
            }
        }
        Write-Output -InputObject ([PSCustomObject]$volumesObject)
    }
}