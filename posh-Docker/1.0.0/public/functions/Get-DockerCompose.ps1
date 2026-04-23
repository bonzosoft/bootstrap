function Get-DockerCompose {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path
    )

    [string[]]$fileContent = @()
    [hashtable]$dockerCompose = @{}

    if (-not (Test-Path -Path $Path.FullName)) {
        throw "File $($Path.FullName) not found."
    }

    $fileContent = docker compose -f $Path.FullName config 2>&1
        #--no-consistency		Don't check model consistency - warning: may produce invalid Compose output
        #--no-env-resolution	Don't resolve service env files
        #--no-interpolate		Don't interpolate environment variables
        #--no-normalize		    Don't normalize compose model (convierte formatos cortos a largos)
        #--no-path-resolution	Don't resolve file paths
    if ($LASTEXITCODE) {
        throw "Unable to generate compose file: $fileContent"
    }

    $dockerCompose = $fileContent | ConvertFrom-Yaml

    return $dockerCompose
}
