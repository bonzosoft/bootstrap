#requires -Version 5
Set-StrictMode -Version Latest

function Merge-EnvEntryInternal {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0 ,ValueFromPipeline)]
        [EnvEntry]$Entry,
        [System.Collections.IDictionary]$InitialEnv,
        [switch]$AllowClobber
    )
    Begin {
        $envs = New-HashTbaleInternal
        if ($null -eq $InitialEnv) {
            $InitialEnv = @{}
        }
    }
    Process {
        if ((-not $AllowClobber) -and $InitialEnv.Contains($Entry.Name)) {
            Write-Verbose "Skip Env: $Entry"
            return
        }
        if ($envs.Contains($Entry.Name)) {
            Write-Verbose "Overwrite Env: $Entry"
        }
        $envs[$Entry.Name] = $Entry.GetValue({
            param($key)
            if ($envs.Contains($key)) {
                return $envs[$key]
            }
            if ($InitialEnv.Contains($key)) {
                return $InitialEnv[$key]
            }
            return ""
        })
    }
    End {
        $envs
    }
}
