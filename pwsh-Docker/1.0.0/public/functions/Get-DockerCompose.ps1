function Get-DockerCompose {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $Script:Context.ComposeFile
    )

    begin {
        [string[]]$composeLines = @()
        [hashtable]$composeData = @{}
    }

    end {
        if (-not (Test-Path -Path $Path.FullName)) {
            throw "File $($Path.FullName) not found."
        }
    
        $composeLines = docker compose -f $Path.FullName config | Out-Null #2>&1
            #--no-consistency		Don't check model consistency - warning: may produce invalid Compose output
            #--no-env-resolution	Don't resolve service env files
            #--no-interpolate		Don't interpolate environment variables
            #--no-normalize		    Don't normalize compose model (convierte formatos cortos a largos)
            #--no-path-resolution	Don't resolve file paths
        if ($LASTEXITCODE) {
            throw "Unable to parse '$Path':`n$composeLines"
        }
        Write-Host $composeLines
        $composeData = $composeLines | ConvertFrom-Yaml
    
        Write-Output $composeData
    }
}
