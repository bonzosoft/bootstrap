function Test-DockerSubmodule {
    [CmdletBinding()]
    [OutputType([bool])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path
    )

    if ($Path.DirectoryName -contains $Script:INCLUDEDIR) {
        return $true
    }
    else {
        return $false
    }
}
