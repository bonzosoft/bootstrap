function Set-DockerConfig {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrWhiteSpace()]
        [string[]]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Service,

        [Parameter()]
        [switch]$Link,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )
   
    begin {
        [IO.FileSystemInfo]$source = $null
        [IO.FileSystemInfo]$target = $null
    }
    process {
        foreach ($item in $Name) {
            $source = Get-Item -Path (Join-Path -Path $MyInvocation.PSScriptRoot -ChildPath (Split-Path -Path $Script:Context.ConfigDir -Leaf) -AdditionalChildPath $item)
            
            if ($source.PSIsContainer) {
                $target = [IO.DirectoryInfo](Join-Path -Path $Script:Context.DataDir -ChildPath $Service -AdditionalChildPath $item)
                $splat = @{
                    Recurse = $true
                }
            }
            else {
                $target = [IO.FileInfo](Join-Path -Path $Script:Context.DataDir -ChildPath $Service -AdditionalChildPath $item)
                $splat = @{
                }
            }

            Write-Host "source: '$source'."
            Write-Host "target: '$target'."
            Write-Host ($target | Out-String)
            
            
            if (-not (Test-Path -Path $source.FullName)) {
                Write-Error -Message "File '$($source.FullName)' not found."
            }

            if ($Link.IsPresent) {
                New-Item -Path $target.FullName -ItemType SymbolicLink -Value $source.FullName -Force:$Force | Out-Null
            }
            else {
                if (-not (Test-Path -Path $target.DirectoryName)) {
                    New-Item -Path $target.DirectoryName -ItemType Directory -Force:$Force | Out-Null
                }
                Copy-Item -Path $source.FullName -Destination $target.FullName -Force:$Force @splat | Out-Null
            }
            
            if ($PassThru.IsPresent) {
                Write-Output -InputObject $source
            }
        }
    }
}
