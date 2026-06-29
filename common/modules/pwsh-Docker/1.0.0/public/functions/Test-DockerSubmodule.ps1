function Test-DockerSubmodule {
    [CmdletBinding()]
    [OutputType([bool])]

    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $MyInvocation.PSScriptRoot
    )

    if ($($Path.DirectoryName).StartsWith($Script:Context.IncludeDir)) {
        Write-Output -InputObject $true
    }
    else {
        Write-Output -InputObject $false
    }
}
