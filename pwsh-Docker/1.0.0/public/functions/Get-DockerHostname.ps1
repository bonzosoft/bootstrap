function Get-DockerHostname {
    [CmdletBinding()]
    [OutputType([string])]

    param ()

    end {
        Write-Output -InputObject (Get-Content "/host/etc/hostname")
    }
}