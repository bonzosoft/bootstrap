function Test-GitProviderSession {
    [CmdletBinding()]
    [OutputType([boolean])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com"
    )

    begin {

    }

    process {
        gh auth status --hostname $Provider *> $null
        if ($LASTEXITCODE) {
            return $false
        }
        else {
            return $true
        }
    }

    end {

    }
}