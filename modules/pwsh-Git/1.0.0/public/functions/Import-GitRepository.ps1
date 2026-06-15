function Import-Repository {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$GitProvider = "github.com",

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Namespace,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Branch = "main",

        [Parameter()]
        [switch]$Force
    )

    begin {
        [IO.DirectoryInfo]$repositoryDir = Join-Path -Path (Get-Location) -ChildPath @($Name)
        [string[]]$scripts = @(
            "onclone.ps1"
            "onpull.ps1"
        )
    }

    process {
        if (Test-Path $repositoryDir) {
            if ($force.IsPresent) {
                Remove-Item -Path $repositoryDir -Recurse -Force
            }
            else {
                Write-Error -Message "Target directory already exists. Use -Force to overwrite it."
            }
        }

        Write-Information -MessageData "Syncing $Namespace/$Name ($Branch)" -InfomationAction 'Continue'
        $null = gh repo clone "$Namespace/$Name" $repositoryDir -- --branch $Branch --single-branch 2> variable:errorMessage
        if ($LASTEXITCODE) {
            Write-Error -Message $errorMessage
        }

        Push-Location -Path $repositoryDir
        git submodule update --init --recursive

        foreach ($script in $scripts) {
            if (Test-Path -Path $script) {
                pwsh -File $script -InfomationAction 'Continue'
            }
        }
        Pop-Location
    }

    end {

    }
}