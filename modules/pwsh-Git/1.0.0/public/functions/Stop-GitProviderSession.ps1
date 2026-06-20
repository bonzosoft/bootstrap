function Stop-GitProviderSession {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com"
    )

    process {
        if (-not (Test-GitProvider)) {
            Write-Warning -Message "No active session"
            return
        }
        gh auth logout --hostname $Provider
    }
}