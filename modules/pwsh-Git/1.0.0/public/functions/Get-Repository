function Get-Repository {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Hostname = "github.com",

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Branch = "main"
    )

    begin {
        $repoOrganization = ($Name -split "/")[0]
        $repoName         = ($Name -split "/")[1]
    }

    process {
        Write-Host "organization $repoOrganization"
        Write-Host "name: $repoName"
    }

    end {

    }
}