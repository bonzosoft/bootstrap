function Assert-GitProviderSession {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$GitProvider = "github.com"
    )

    begin {
        [string[]]$errorMessage = @()
    }

    process {
        $null = gh auth setup-git --hostname $GitProvider 2> variable:errorMessage
        if ($LASTEXITCODE) {
            throw $errorMessage
        }
    }
    
    end {

    }
}