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
            Write-Host "No GH session."
            return $false
        }
        else {
            (printf "protocol=https\nhost=github.com\n\n" | git credential fill) *> $null
            if ($LASTEXTICODE) {
                Write-Host "No Git session."
                return $false
            }
            else {
                Write-Host "Correct GH and Git session."
                return $true
            }
        }
    }

    end {

    }
}