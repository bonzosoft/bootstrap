function Get-DockerHostname {
    [CmdletBinding()]
    [OutputType([string])]

    param (

    )

    end {
        Write-Output (Get-Content "/host/etc/hostname")
    }
}