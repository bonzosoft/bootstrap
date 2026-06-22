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
        Write-Host "lastexitcode: $LASTEXITCODE"
        if ($LASTEXITCODE) {
            Write-Host "No GH session."
            return $false
        }

        printf "protocol=https\nhost=github.com\n\n" | git credential fill *> $null
        Write-Host "lastexitcode: $LASTEXITCODE"
        if ($LASTEXTICODE) {
            Write-Host "No Git session."
            return $false
        }
        
        Write-Host "Correct GH and Git session."
        return $true
    }

    end {

    }
}