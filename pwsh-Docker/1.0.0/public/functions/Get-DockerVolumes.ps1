function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$InputObject,

        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service #= $InputObject.services.Keys
    )

    begin {
        Write-Host "la funcion pasa por aqui ####################################################"
        Write-Host $Service
        [IO.FileSystemInfo[]]$volumesList = @()
        [hashtable]$volumesObject = @{}

        if (-not $Service.Count) {
            $Service = $InputObject.services.Keys
        }
    }

    end {
        foreach ($service in $InputObject.services.Keys) {
            if ($InputObject.services.$service.Keys -like "volumes") {
                $volumesList = @()
                foreach ($volume in $InputObject.services.$service.volumes.source) {
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
                    $volumesObject[$service] = $volumesList
                }
                
            }
        }
        Write-Output -InputObject ([PSCustomObject]$volumesObject)
    }
}