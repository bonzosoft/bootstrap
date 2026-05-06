function Test-DockerSubmodule {
    [CmdletBinding()]
    [OutputType([bool])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $MyInvocation.PSScriptRoot
    )

    if ($($Path.DirectoryName).StartsWith($Script:Context.IncludeDir)) {
        return $true
    }
    else {
        return $false
    }
}
