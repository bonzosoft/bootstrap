
function Grant-DockerPermission {
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType([void])]

    param (
        [Parameter(Mandatory, ParameterSetName="File")]
        [ValidateNotNullOrWhiteSpace()]
        $Path,

        [Parameter(Mandatory)]
        [ValidateRange(0,65535)]
        [int]$PUID,

        [Parameter(Mandatory)]
        [ValidateRange(0,65535)]
        [int]$PGID,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-7]{3,4}$')] # Ensures valid octal format (e.g., '755' or '0644')
        [string]$Mode,

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [switch]$Force
    )

    begin {
        [Collections.Generic.List[IO.DirectoryInfo]]$directories = @()
        [Collections.Generic.List[IO.FileInfo]]$files = @()
        [string]$directoryMode = ""
        [string]$fileMode = ""
        [int]$digit = 0

        $directoryMode = $Mode
        $fileMode = -join ($Mode.ToCharArray() | ForEach-Object {
            $digit = [int]$PSItem
            if ($digit % 2) {
                $digit-1
            }
            else {
                $digit
            }
        })
        Write-Host "File mode: $fileMode"
        Write-Host "Directory mode: $directoryMode"
    }

    process {
        
        if (-not (Test-Path -Path $Path)) {
            $directories += New-Item -Path $Path -ItemType Directory -Force
        }
        else {
            if ($Path.Attributes -band [System.IO.FileAttributes]::Directory) {
                $directories = @($Path; Get-ChildItem -Path $Path -Directory -Force:$Force -Recurse)
                $files = @(Get-ChildItem -Path $Path -File -Force:$Force -Recurse)
            }
            else {
                $directories = @()
                $files = @($Path)
            }
        }

        if ($IsLinux) {
            if ($directories) {
                $directories.FullName | xargs -r chown "${PUID}:${PGID}" 
                $directories.FullName | xargs -r chmod $directoryMode
            }
            if ($files) {
                $files.FullName | xargs -r chown "${PUID}:${PGID}" 
                $files.FullName | xargs -r chmod $fileMode
            }
        }
    }
}
