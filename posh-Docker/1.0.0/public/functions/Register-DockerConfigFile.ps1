function Register-DockerConfigFile {

    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [IO.FileInfo]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name
    )

    [IO.FileInfo]$configFile = $null
    #$var = Get-DockerCompose -Path (Join-Path -Path $Path.Directory -ChildPath "compose.yaml")
    $var = Get-Content -Path (Join-Path -Path $Path.Directory -ChildPath "compose.yaml") -Raw -Encoding UTF8 | ConvertFrom-Yaml
    $service = $var.services.Keys[0]
    
    if (Test-DockerSubmodule -Path $Path.DirectoryName) {
        $configFile = Join-Path -Path $Script:INCLUDEDIR -ChildPath $Path.Directory.BaseName -AdditionalChildPath $Script:CONFIGDIR.BaseName
        $configFile = Join-Path -Path $configFile.FullName -ChildPath $Name
    }
    else {
        $configFile = Join-Path -Path $Script:CONFIGDIR -ChildPath $Name
    }
    
    New-Item -Path (Join-Path -Path $Script:DATADIR -ChildPath $service -AdditionalChildPath $Name) -ItemType SymbolicLink -Value $configFile -Force | Out-Null
}
