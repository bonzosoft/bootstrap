function Import-GitRepository {
    [CmdletBinding()]
    [OutputType([void])]

    param(
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$Provider = "github.com",

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
        [IO.DirectoryInfo]$repositoryDir = Join-Path -Path ${PWD} -ChildPath $Repository
        [string[]]$scripts = @(
            "onclone.ps1"
            "onpull.ps1"
        )
    }

    process {
        if (Test-Path $repositoryDir) {
            if ($Force.IsPresent) {
                Remove-Item -Path $repositoryDir -Recurse -Force
            }
            else {
                Write-Error -Message "Target directory already exists. Use -Force to overwrite it."
                return # Añadido un return para que no intente clonar si ya existe y no hay -Force
            }
        }

        Write-Information -MessageData "Syncing ${Namespace}/${Repository} ($Branch)" -InformationAction 'Continue'
        
        $null = git clone --branch $Branch --single-branch "https://${Provider}/${Namespace}/${Repository}.git" $repositoryDir.FullName 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            throw $errorMessage
        }

        Push-Location -Path $repositoryDir
        $null = git submodule update --init --recursive 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            throw $errorMessage
        }

        foreach ($script in $scripts) {
            [IO.FileInfo]$scriptPath = (Join-Path -Path $PWD -ChildPath $script)
            if (Test-Path -Path $scriptPath) {
                pwsh -File $scriptPath.FullName -InformationAction 'Continue'
            }
        }
        Pop-Location
    }

    end {
    }
}