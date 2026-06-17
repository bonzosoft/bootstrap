function Disconnect-GitProvider {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$GitProvider = "github.com"
    )

    process {
        if (-not (Test-GitProvider)) {
            Write-Error -Message "No active session"
            return
        }
    
        gh auth logout --hostname $GitProvider
        Write-Information -MessageData "Logged out." -InformationAction 'Continue'
    }
}