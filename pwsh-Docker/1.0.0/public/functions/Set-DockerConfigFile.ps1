function Set-DockerConfigFile {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrWhiteSpace()]
        [IO.FileInfo[]]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Target,

        [Parameter()]
        [switch]$Link,

        [Parameter()]
        [switch]$Force
    )
   
    process {
        foreach ($item in $Path) {
            if ($Link.IsPresent) {
                New-Item -Path $item.FullName -ItemType SymbolicLink -Value $Target -Force:$Force | Out-Null
            }
            else {
                Copy-Item -Path $item.FullName -Destination $target -Force:$Force | Out-Null
            }           
        }
    }
}
