#requires -Version 5
Set-StrictMode -Version Latest

function Read-Dotenv {
    <#
    .SYNOPSIS
        Reads a dotenv-formatted file and returns it in Hashtable format.
    .DESCRIPTION
        This cmdlet converts a dotenv(.env) formatted string into either a Hashtable or a EnvEntry array.
    .EXAMPLE
        PS C:\> Read-Dotenv ".env"

        ----                           -----
        ABC                            1
        DEF                            3

    #>
    [CmdletBinding(DefaultParametersetName = "Hashtable")]
    [OutputType([hashtable], ParameterSetName = "Hashtable")]
    [OutputType([EnvEntry[]], ParameterSetName = "EnvEntry")]
    Param(
        # Specifies a Path Name of the .env.
        [Parameter(Position = 0 , ValueFromPipeline, ParameterSetName = "Hashtable")]
        [Parameter(Position = 0 , ValueFromPipeline, ParameterSetName = "EnvEntry")]
        [string[]]$Path,
        # Environment variables for variable expansion; defaults to retrieving from the Env: drive.
        [Parameter(ParameterSetName = "Hashtable")]
        [System.Collections.IDictionary]$InitialEnv = (Get-EnvHashtableInternal),
        # Enables the behavior to OVERRIDE environment variables.
        [Parameter(ParameterSetName = "Hashtable")]
        [switch]$AllowClobber,
        # Specifies the encoding type for .env. The default value is UTF-8.
        [Parameter(ParameterSetName = "Hashtable")]
        [Parameter(ParameterSetName = "EnvEntry")]
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8,
        # Converts the Dotenv to an EnvEntry object.
        # Ignore errors if the file does not exist.
        [Parameter(ParameterSetName = "Hashtable")]
        [Parameter(ParameterSetName = "EnvEntry")]
        [switch]$SkipReadErrorCheck,
        [Parameter(ParameterSetName = "EnvEntry")]
        [switch]$AsEnvEntry
    )
    Begin {
        function GetDotFileContent ([string]$f) {
            try {
                Get-Content -Path $f -Encoding $Encoding -Raw -ErrorAction Stop
            }
            catch {
                if (-not $SkipReadErrorCheck) {
                    throw $_
                }
                Write-Verbose $_
            }
            return ""
        }

        $dotenv_files = @();
    }
    Process {
        $dotenv_files += @($Path | Where-Object { -not ([string]::IsNullOrEmpty($_)) })
    }
    End {

        if ($dotenv_files.Count -eq 0) {
            $dotenv_files += @(".env")
        }

        $dotenv_contents = $dotenv_files | ForEach-Object {
            $c = GetDotFileContent $_
            Write-Debug "Read dotfile: $_"
            $c
        }

        $dotenv_entry = $dotenv_contents | ConvertFrom-Dotenv -AsEnvEntry

        if ($AsEnvEntry) {
            $dotenv_entry
        }
        else {
            $dotenv_entry | Merge-EnvEntryInternal -InitialEnv $InitialEnv -AllowClobber:$AllowClobber
        }

    }
}
