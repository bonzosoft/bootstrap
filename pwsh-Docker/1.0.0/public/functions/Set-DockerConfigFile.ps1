function Set-DockerConfigFile {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        #[ValidateNotNullOrEmpty()]
        [IO.FileInfo[]]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]$Destination,

        [Parameter()]
        [switch]$Link,

        [Parameter()]
        [switch]$Force
    )
   
    begin {
        [IO.FileInfo]$target = $null
    }
    process {
        foreach ($item in $Path) {
            Write-Host $item
            if (-not (Test-Path -Path $item.FullName)) {
                Write-Error -Message "File '$($item.FullName)' not found."
            }
            
            $target = Join-Path -Path $Destination -ChildPath $item.Name
            Write-Host "item: $item"
            Write-host "target2: $target"

            if ($Link.IsPresent) {
                New-Item -Path $target.FullName -ItemType SymbolicLink -Value $item.FullName -Force:$Force | Out-Null
            }
            else {
                Copy-Item -Path $item.FullName -Destination $target.FullName -Force:$Force | Out-Null
            }           
        }
    }
}
