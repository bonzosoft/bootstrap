function Test-GitProviderSession {
    [CmdletBinding()]
    [OutputType([boolean])]

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com",

        [Parameter()]
        [switch]$GithubCLI,

        [Parameter()]
        [switch]$Git
    )

    begin {
        [bool]$switchGithubCLI = $GitHubCLI.IsPresent
        [bool]$switchGit       = $Git.IsPresent

        if ((-not $switchGithubCLI) -and (-not $switchGit)) {
            $switchGithubCLI = $true
            $switchGit       = $true
        }
    }

    process {
        if ($switchGithubCLI) {
            $null = gh auth status --hostname $Provider 2> $null
            if ($LASTEXITCODE) {
                return $false
            }
        }
        
        if ($switchGit) {
            $null = printf "protocol=https\nhost=github.com\n\n" | git credential fill 2> $null
            if ($LASTEXITCODE) {
                return $false
            }
        }
        
        return $true
    }

    end {

    }
}