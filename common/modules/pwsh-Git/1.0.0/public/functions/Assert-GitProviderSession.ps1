function Assert-GitProviderSession {
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
        $null = gh auth setup-git --hostname $Provider 2> variable:errorMessage
        if ($LASTEXITCODE) {
            throw $errorMessage
        }
    }
    
    end {

    }
}