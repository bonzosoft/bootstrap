function Register-DockerConfig {

    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [IO.FileInfo]$Path

        #[Parameter(Mandatory)]
        #[ValidateNotNullOrWhiteSpace()]
        #[string]$Name
    )

    [IO.FileInfo[]]$configFiles = $null

    $var = Get-Content -Path (Join-Path -Path $Path.Directory -ChildPath "compose.yaml") -Raw -Encoding UTF8 | ConvertFrom-Yaml
    $service = $var.services.Keys[0]
    
    if (Test-DockerSubmodule -Path $Path.DirectoryName) {
        $configFiles = Get-ChildItem -Path (Join-Path -Path $Script:INCLUDEDIR -ChildPath $Path.Directory.BaseName -AdditionalChildPath $Script:CONFIGDIR.BaseName)
    }
    else {
        $configFiles = Get-ChildItem -Path (Join-Path -Path $Script:CONFIGDIR)
    }
    
    foreach ($file in $configFiles) {
        New-Item -Path (Join-Path -Path $Script:DATADIR -ChildPath $service -AdditionalChildPath $file.Name) -ItemType SymbolicLink -Value $file.FullName -Force | Out-Null
    }
}
