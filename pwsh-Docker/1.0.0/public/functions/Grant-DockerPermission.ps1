
function Grant-DockerPermission {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrWhiteSpace()]
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
        [switch]$Force
    )

    begin {
        [Collections.Generic.List[IO.DirectoryInfo]]$directories = @()
        [Collections.Generic.List[IO.FileInfo]]$files = @()
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
        #Write-Host "File mode: $filePermission"
        #Write-Host "Directory mode: $directoryPermission"
    }

    process {
        foreach ($item in $Path) {
            if (-not (Test-Path -Path $item)) {
                $directories += New-Item -Path $Path -ItemType Directory -Force:$Force
            }
            else {
                $temporaryItem = Get-Item -Path $item -Force:$Force
                if ($temporaryItem -is [IO.FileInfo]) {
                    #$files.Add($temporaryItem)
                    $files += $temporaryItem               
                }
                if ($temporaryItem -is [IO.DirectoryInfo]) {
                    $directories.Add($temporaryItem)
                    if ($Recurse.IsPresent) {
                        #$files.AddRange((Get-ChildItem -Path $item -File -Force:$Force -Recurse))
                        #$directories.AddRange((Get-ChildItem -Path $item -Directory -Force:$Force -Recurse))
                        $files += Get-ChildItem -Path $item -File -Force:$Force -Recurse
                        $directories += Get-ChildItem -Path $item -Directory -Force:$Force -Recurse
                    }
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
    }
}
