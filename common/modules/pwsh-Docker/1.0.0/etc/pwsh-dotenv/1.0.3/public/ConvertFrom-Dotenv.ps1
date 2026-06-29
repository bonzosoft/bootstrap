#requires -Version 5
Set-StrictMode -Version Latest

function ConvertFrom-Dotenv {
    <#
    .SYNOPSIS
        Converts a dotenv-formatted(.env) string into a hash table or a EnvEntry object.
    .DESCRIPTION
        This cmdlet converts a dotenv(.env) formatted string into either a Hashtable or a EnvEntry array.
    .EXAMPLE
        PS C:\> ConvertFrom-Dotenv "ABC=1`nDEF=2"

        ----                           -----
        ABC                            1
        DEF                            3

    #>
    [CmdletBinding(DefaultParametersetName = "Hashtable")]
    [OutputType([hashtable], ParameterSetName = "Hashtable")]
    [OutputType("EnvEntry[]", ParameterSetName = "EnvEntry")]
    Param(
        # Specifies the .env strings to convert to  a Hashtable or a EnvEntry array.
        [Parameter(Position = 0 , ValueFromPipeline, ParameterSetName = "Hashtable")]
        [Parameter(Position = 0 , ValueFromPipeline, ParameterSetName = "EnvEntry")]
        [string[]]$InputObject,
        # Environment variables for variable expansion; defaults to retrieving from the Env: drive.
        [Parameter(ParameterSetName = "Hashtable")]
        [System.Collections.IDictionary]$InitialEnv = (Get-EnvHashtableInternal),
        # Enables the behavior to OVERRIDE environment variables.
        [Parameter(ParameterSetName = "Hashtable")]
        [switch]$AllowClobber,
        # Converts the Dotenv to an EnvEntry object.
        [Parameter(ParameterSetName = "EnvEntry")]
        [switch]$AsEnvEntry
    )
    Begin {
        $dotenv_list = [System.Collections.ArrayList]::new()
        function parseDotFile ([string]$str) {
            $prev_str = $str
            while ($true) {
                if ("" -eq $str) {
                    break;
                }
                $str = Remove-LineCommentInternal $str
                $env_entry, $str = Split-KeyValueInternal $str
                if ($null -ne $env_entry) {
                    Write-Debug "parse dotenv: $env_entry"
                    $null = $dotenv_list.Add($env_entry)
                }
                if ($prev_str -eq $str) {
                    break;
                }
                if ($null -eq $str) {
                    $str = ""
                }
                $prev_str = $str
            }
        }
    }
    Process {
        $InputObject | ForEach-Object {
            parseDotFile $_
        }
    }
    End {

        if ($AsEnvEntry) {
            return $dotenv_list.ToArray()
        }
        else {
            $envs = New-HashTbaleInternal
            if ($null -eq $InitialEnv) {
                $InitialEnv = @{}
            }

            $envs = $dotenv_list | Merge-EnvEntryInternal -InitialEnv $InitialEnv -AllowClobber:$AllowClobber
            return $envs;
        }
    }
}
