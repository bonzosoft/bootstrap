
function Grant-DockerPermission {
    [CmdletBinding()]
    [OutputType([void])]
    [OutputType([IO.FileSystemInfo[]])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [IO.FileSystemInfo[]]$Path,

        [Parameter(Mandatory)]
        [ValidateRange(0,65535)]
        [int]$PUID,

        [Parameter(Mandatory)]
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
        [string]$directoryPermission = ""
        [string]$filePermission = ""
        [int]$digit = 0

        $directoryPermission = $Permission
        $filePermission = -join ($Permission.ToCharArray() | ForEach-Object {
            $digit = [int]::Parse($PSItem)
            if ($digit % 2) {
                $digit-1
            }
            else {
                $digit
            }
        })
    }

    process {
        foreach ($item in $Path) {
            if (-not ($($item.FullName).StartsWith($Script:Context.DataDir))) {
                Write-Host "System directory. Skipping."
                continue
            }

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
                $directories.FullName | xargs -r chmod $directoryPermission
            }
            if ($files) {
                $files.FullName | xargs -r chown ${PUID}:${PGID}
                $files.FullName | xargs -r chmod $filePermission
            }
        }
        
        if ($PassThru.IsPresent) {
            return $Path
        }
    }
}
