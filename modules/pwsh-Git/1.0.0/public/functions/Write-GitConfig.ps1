function Write-GitConfig {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Data
    )

    begin {

    }

    process {
        $Data | ConvertTo-Json | Set-Content -Path $Path
    }

    end {

    }

}