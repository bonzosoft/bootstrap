
function Grant-DockerPermission {
    [CmdletBinding()]
    [OutputType([void])]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [IO.FileSystemInfo[]]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0,65535)]
        [int]$PUID,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0,65535)]
        [int]$PGID,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-7]{3,4}$')] # Ensures valid octal format (e.g., '755' or '0644')
        [string]$Permission,

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [IO.FileInfo[]]$files = @()
        [IO.DirectoryInfo[]]$directories = @()
        [IO.UnixFileMode]$directoryPermission = ConvertTo-UnixFileMode -Octal $Permission
        [IO.UnixFileMode]$filePermission = $directoryPermission - ([IO.UnixFileMode]::UserExecute + [IO.UnixFileMode]::GroupExecute + [IO.UnixFileMode]::OtherExecute)
    }

    process {
        foreach ($item in $Path) {
            if (-not (Test-Path -Path $item)) {
                $directories += New-Item -Path $item -ItemType Directory -Force:$Force
            }
            else {
                $temporaryItem = Get-Item -Path $item -Force:$Force
                if ($temporaryItem -is [IO.FileInfo]) {
                    $files += $temporaryItem
                    continue
                }

                if ($temporaryItem -is [IO.DirectoryInfo]) {
                    $directories += @($temporaryItem)
                    if ($Recurse.IsPresent) {
                        $files += Get-ChildItem -Path $item -File -Force:$Force -Recurse
                        $directories += Get-ChildItem -Path $item -Directory -Force:$Force -Recurse
                    }
                    continue
                }
            }
        }
    }

    end {
        if ($IsLinux) {
            
            if ($directories) {
                $directories.FullName | xargs -r chown ${PUID}:${PGID}
                [IO.File]::SetUnixFileMode($directories.FullName, $directoryPermission)
                #$directories.FullName | xargs -r chmod $directoryPermission
            }
            if ($files) {
                $files.FullName | xargs -r chown ${PUID}:${PGID}
                [IO.File]::SetUnixFileMode($files.FullName, $filePermission)
                #$files.FullName | xargs -r chmod $filePermission
            }
        }
        
        if ($PassThru.IsPresent) {
            Write-Output -InputObject $Path
        }
    }
}
