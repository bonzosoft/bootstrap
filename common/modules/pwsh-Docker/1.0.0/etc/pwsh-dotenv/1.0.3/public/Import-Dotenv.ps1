#requires -Version 5
Set-StrictMode -Version Latest

function Import-Dotenv {
    <#
    .SYNOPSIS
        Reads a dotenv-formatted file and returns it in Hashtable format.
    .DESCRIPTION
        This cmdlet converts a dotenv(.env) formatted string into either a Hashtable or a EnvEntry array.
    .EXAMPLE
        PS C:\> Import-Dotenv

        .EXAMPLE
        PS C:\> Import-Dotenv ".test.env" -PassThru

        ----                           -----
        ABC                            1
        DEF                            3

    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable], ParameterSetName = "Hashtable")]
    Param(
        # Specifies a Path Name of the .env.
        [Parameter(Position = 0 , ValueFromPipeline)]
        [string[]]$Path,
        # Enables the behavior to OVERRIDE environment variables.
        [Parameter()]
        [switch]$AllowClobber,
        # Specifies the encoding type for .env. The default value is UTF-8.
        [Parameter()]
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8,
        # Ignore errors if the file does not exist.
        [Parameter()]
        [switch]$SkipReadErrorCheck,
        # Returns an hashtable representing the imported dotenv. By default, this cmdlet doesn't generate any output.
        [Parameter(ParameterSetName = "Hashtable")]
        [switch]$PassThru
    )
    Begin {
        $dotenv_files = @()
    }
    Process {
        $dotenv_files += @($Path)
    }
    End {

        $envs = Read-Dotenv -Path $dotenv_files -AllowClobber:$AllowClobber -Encoding $Encoding -SkipReadErrorCheck:$SkipReadErrorCheck

        foreach ($name in $envs.Keys) {
            $env_path = Join-Path -Path "${script:EnvDriveName}:" -ChildPath $name
            $value = $envs[$name]
            if($PSCmdlet.ShouldProcess("Set ${env_path}=${value}")){
                Set-Content -LiteralPath $env_path -Value $value -Confirm:$false
                Write-Verbose "Set ${env_path}=${value}"
            }
        }

        if($PassThru){
            $envs
        }
    }
}
