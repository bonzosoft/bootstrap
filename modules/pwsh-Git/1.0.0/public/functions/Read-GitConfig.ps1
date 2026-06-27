function Read-GitConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path
    )

    begin {
        [hashtable]$config = [ordered]@{
            Tenant = ""
        }
    }

    process {
        if (Test-Path -Path $Path) {
            $config = Get-Content -Path $Path | ConvertFrom-Json -Depth 9 -AsHashtable
        }
        else {
            New-Item -Path $Path.DirectoryName -ItemType 'Directory' -Force
            Write-GitConfig -Path $Path -Value $config
        }
    }
    
    end {
        return $config
    }
}