function Get-DockerVolumes {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$InputObject,

        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = $InputObject.services.Keys
    )

    begin {
        Write-Host "la funcion pasa por aqui ####################################################"
        [IO.FileSystemInfo[]]$volumesList = @()
        [hashtable]$volumesObject = @{}

        #if (-not $Service.Count) {
        #    $Service = $InputObject.services.Keys
        #}
    }#

    process {
        Write-Host $Service
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