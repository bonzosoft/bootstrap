function Read-GitConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path
    )

    begin {
        [hashtable]$config = @{
            Tenant = "AST"
        }
    }

    process {
        if (Test-Path -Path $Path) {
            $config = Get-Content -Path $Path | ConvertFrom-Json -Depth 9 -AsHashtable
        }
        else {
            New-Item -Path $Path.DirectoryName -ItemType 'Directory' -Force
            $config | ConvertTo-Json | Set-Content -Path $Path
        }
    }
    
    end {
        return $config
    }
}