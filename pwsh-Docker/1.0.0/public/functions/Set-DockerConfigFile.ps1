function Set-DockerConfigFile {
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
        [IO.FileInfo]$source = $null
        [IO.FileInfo]$target = $null
    }
    process {
        foreach ($item in $Name) {
            #$source = Join-Path -Path $MyInvocation.PSScriptRoot -ChildPath (Split-Path -Path $Script:Context.ConfigDir -Leaf) -AdditionalChildPath $item
            $source = Get-Item -Path (Join-Path -Path $MyInvocation.PSScriptRoot -ChildPath $Script:Context.ConfigDir.Name -AdditionalChildPath $item)
            $target = Join-Path -Path $Script:Context.DataDir -ChildPath $Service -AdditionalChildPath $item
            
            Write-Host "source: '$source'."
            Write-Host "target: '$target'."
            
            if (-not (Test-Path -Path $target.DirectoryName)) {
                New-Item -Path $taget.DirectoryName -ItemType Directory -Force:$Force
            }
            
            if ($Link.IsPresent) {
                New-Item -Path $target.FullName -ItemType SymbolicLink -Value $source.FullName -Force:$Force | Out-Null
            }
            else {
                Copy-Item -Path $source.FullName -Destination $target.FullName -Force:$Force | Out-Null
            }
            
            if ($PassThru.IsPresent) {
                Write-Output -InputObject $source
            }
        }
    }
}
