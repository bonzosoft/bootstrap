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
            (printf "protocol=https\nhost=github.com\n\n" | git credential fill) *> $null
            if ($LASTEXTICODE) {
                return $false
            }
            else {
                return $true
            }
        }
    }

    end {

    }
}