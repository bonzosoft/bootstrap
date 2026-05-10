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
        [IO.FileSystemInfo[]]$volumes = @()
        [hashtable]$servicesTable = @{}
    }

    process {
        foreach ($item in $Service) {
            #if ($InputObject.services.$item.Keys -like "volumes") {
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
                #if ($volumesList.Count) {
                    $servicesTable[$item] = @{
                        Volume = $volumesList
                        PUID = [int]($InputObject.services.$item.user -split ":")[0]
                        PGID = [int]($InputObject.services.$item.user -split ":")[1]
                    }
                #}
            #}
        }
        Write-Output -InputObject $servicesTable
    }
}
