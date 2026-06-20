function Start-GitProviderSession {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com"
    )

    begin {
        [string[]]$errorMessage = @()
    }

    process {
        gh auth login --hostname $Provider --git-protocol https --web 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            throw $errorMessage
        }

        Assert-GitProviderSession -Provider $Provider
    }

    end {

    }
}