function Test-DockerIsTruenas {
    [CmdletBinding()]
    [OutputType([bool])]

    param ()

    end {
        Write-Output -InputObject (Test-Path "/host/etc/version")
    }
}