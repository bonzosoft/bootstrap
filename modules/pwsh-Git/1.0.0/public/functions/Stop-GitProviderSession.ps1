function Stop-GitProviderSession {
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
        if (Test-GitProviderSession -Provider $Provider -GithubCLI) {
            $null = gh auth logout --hostname $Provider 2> variable:errorMessage
            if ($LASTEXITCODE) {
                return $errorMessage
            }
        }
        else {
            Write-Warning -Message "No active session found."
        }
    }

    end {

    }
}