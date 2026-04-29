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
        Write-Host ($MyInvocation | Format-List *)
        foreach ($item in $Path) {
            if ($Link.IsPresent) {
                New-Item -Path $Target -ItemType SymbolicLink -Value $item.FullName -Force:$Force | Out-Null
            }
            else {
                Copy-Item -Path $item.FullName -Destination $Target -Force:$Force | Out-Null
            }           
        }
    }
}
