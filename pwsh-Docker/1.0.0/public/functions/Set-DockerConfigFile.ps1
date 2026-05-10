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
            $source = Join-Path -Path $MyInvocation.PSScriptRoot -ChildPath (Split-Path -Path $Script:Context.ConfigDir -Leaf) -AdditionalChildPath $item
            $target = Join-Path -Path $Script:Context.DataDir -ChildPath $Service -AdditionalChildPath $item
            
            if (-not (Test-Path -Path $source.FullName)) {
                Write-Error -Message "File '$($source.FullName)' not found."
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
