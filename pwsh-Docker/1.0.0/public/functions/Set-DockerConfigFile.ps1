function Set-DockerConfigFile {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrWhiteSpace()]
        [IO.FileInfo[]]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Service,

        [Parameter()]
        [switch]$Link,

        [Parameter()]
        [switch]$Force
    )

    begin {
        [string]$target = ""
    }
    
    process {
        foreach ($item in $Path) {
            $target = Join-Path -Path $Script:DATADIR -ChildPath $Service -AdditionalChildPath $item.Name
            if ($Link.IsPresent) {
                New-Item -Path $item.FullName -ItemType SymbolicLink -Value $target -Force:$Force | Out-Null
            }
            else {
                Copy-Item -Path $item.FullName -Destination $target -Force:$Force | Out-Null
            }           
        }
    }
}
