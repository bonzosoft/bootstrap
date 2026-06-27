function Import-GitRepository {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com",

        [Parameter()]
        [ValidateSet("https", "ssl")]
        [string]$Protocol = "https",

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Namespace,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Repository,

        [Parameter()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Branch = "main",

        [Parameter()]
        [switch]$Force
    )

    begin {
        [string[]]$errorMessage = @()
        [IO.DirectoryInfo]$repositoryDir = Join-Path -Path $PWD -ChildPath $Repository
        [string[]]$scripts = @(
            "onclone.ps1"
            "onpull.ps1"
        )
        [IO.FileInfo]$scriptPath = $null
    }

    process {
        Write-Information -MessageData "Syncing ${Namespace}/${Repository} ($Branch)"

        if (Test-Path $repositoryDir) {
            if ($Force.IsPresent) {
                Remove-Item -Path $repositoryDir -Recurse -Force
            }
            else {
                throw "Target directory already exists. Use -Force to overwrite it."
            }
        }
        
        switch ($Protocol) {
            "https" {
                $null = git clone --branch $Branch --single-branch "https://${Provider}/${Namespace}/${Repository}.git" $repositoryDir.FullName 2> variable:errorMessage
                if ($LASTEXITCODE) {
                    throw $errorMessage
                }
            }
            default {
                throw "Protocol not implemented yet."
            }
        }

        Push-Location -Path $repositoryDir
            $null = git submodule update --init --recursive 2> variable:errorMessage
            if ($LASTEXITCODE) {
                throw $errorMessage
            }

            foreach ($script in $scripts) {
                $scriptPath = Join-Path -Path $PWD -ChildPath $script
                if (Test-Path -Path $scriptPath) {
                    pwsh -File $scriptPath.FullName -InformationAction 'Continue'
                }
                else {
                    Write-Warning -Message "Script '$scriptPath' not found."
                }
            }
        Pop-Location
    }

    end {
        
    }
}