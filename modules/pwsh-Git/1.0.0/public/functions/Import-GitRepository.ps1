function Import-GitRepository {
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
        [IO.DirectoryInfo]$repositoryDir = Join-Path -Path (Get-Location) -ChildPath $Name
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

        # Corregido: InfomationAction -> InformationAction
        Write-Information -MessageData "Syncing $Namespace/$Name ($Branch)" -InformationAction 'Continue'
        
        $null = git clone --branch "$Branch" --single-branch "https://$GitProvider/$Namespace/$Name.git" "$repositoryDir" 2> variable:errorMessage
        if ($LASTEXITCODE -ne 0) {
            Write-Error -Message $errorMessage
            return # Evitamos entrar al directorio si falló la clonación
        }

        Push-Location -Path $repositoryDir
        git submodule update --init --recursive

        foreach ($script in $scripts) {
            if (Test-Path -Path $script) {
                # Corregido: InfomationAction -> InformationAction
                pwsh -File $script -InformationAction 'Continue'
            }
        }
        Pop-Location
    }

    end {
    }
}