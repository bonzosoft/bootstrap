function Set-DockerConfigFile {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        #[ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Service,

        [Parameter()]
        [switch]$Link,

        [Parameter()]
        [switch]$Force
    )
   
    begin {
        [IO.FileInfo]$source = 
        [IO.FileInfo]$target = $null
    }
    process {
        foreach ($item in $Name) {
            Write-Host $item
            $source = Join-Path -Path $MyInvocation.PSCommandPath -ChildPath (Split-Path -Path $Script:Context.ConfigDir -Leaf) -AdditionalChildPath $item
            $target = Join-Path -Path $Script:Context.DataDir -ChildPath $Service
            if (-not (Test-Path -Path $source.FullName)) {
                Write-Error -Message "File '$($source.FullName)' not found."
            }
            
            Write-Host "source: $source"
            Write-host "target: $target"

            if ($Link.IsPresent) {
                New-Item -Path $target.FullName -ItemType SymbolicLink -Value $source.FullName -Force:$Force | Out-Null
            }
            else {
                Copy-Item -Path $source.FullName -Destination $target.FullName -Force:$Force | Out-Null
            }           
        }
    }
}
