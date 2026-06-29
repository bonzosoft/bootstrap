function Start-GitProviderSession {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com",

        [Parameter()]
        [ValidateSet("https", "ssh")]
        [string]$Protocol = "https"
    )

    begin {
        [string[]]$errorMessage = @()
    }

    process {
        gh auth login --hostname $Provider --git-protocol $Protocol --web 2> variable:errorMessage
        if ($LASTEXITCODE) {
            throw $errorMessage
        }

        Assert-GitProviderSession -Provider $Provider
    }

    end {

    }
}