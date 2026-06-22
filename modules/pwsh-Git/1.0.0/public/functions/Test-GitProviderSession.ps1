function Test-GitProviderSession {
    [CmdletBinding()]
    [OutputType([boolean])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com",

        [Parameter()]
        [switch]$GH,

        [Parameter()]
        [switch]$Git
    )

    begin {
        if ((-not $GH.IsPresent) -and (-not $Git.IsPresent)) {
            $GH = $true
            $Git = $true
        }
        
    }

    process {
        if ($GH) {
            gh auth status --hostname $Provider *> $null
            if ($LASTEXITCODE) {
                return $false
            }
        }
        
        if ($Git) {
            printf "protocol=https\nhost=github.com\n\n" | git credential fill *> $null
            if ($LASTEXITCODE) {
                return $false
            }
        }
        
        return $true
    }

    end {

    }
}