function Connect-GitProvider {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$GitProvider = "github.com",

        [Parameter()]
        [switch]$Force
    )

    process {
        Write-Information -MessageData "Checking authentication." -InformationAction 'Continue'
        if (-not (Test-GitProvider) -Or $Force) {
            gh auth login --hostname $GitProvider --git-protocol https --web
            if ($LASTEXITCODE -ne 0) {
                throw "Login failed."
            }
        }

        gh auth setup-git *> $null
        Write-Information -MessageData "Login succeeded." -InformationAction 'Continue'
    }
}