function Get-DockerHostname {
    [CmdletBinding()]
    [OutType([string])]

    param (

    )

    end {
        Write-Output Get-Content "/host/etc/hostname"
    }
}