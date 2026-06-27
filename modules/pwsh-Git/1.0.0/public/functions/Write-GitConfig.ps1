function Write-GitConfig {
    [CmdletBinding()]
    [OutputType([void])]

    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Value
    )

    begin {

    }

    process {
        Set-Content -Path $Path -Value ($Value | ConvertTo-Json)
    }

    end {

    }

}