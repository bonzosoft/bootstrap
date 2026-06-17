function Assert-GitProvider {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$GitProvider = "github.com"
    )

    process {
        gh auth setup-git --hostname $GitProvider
        Write-Information -MessageData "Login OK" -InformationAction 'Continue'
    }
}