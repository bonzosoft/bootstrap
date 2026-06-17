function Test-GitProvider {
    [CmdletBinding()]
    [OutputType([boolean])] # Corregido: Cambiado [void] a [boolean] porque devuelves un true/false

    param (
        [Parameter()]
        [ValidateSet("github.com")]
        [string]$GitProvider = "github.com"
    )

    process {
        gh auth status --hostname $GitProvider *> $null
        return ($LASTEXITCODE -eq 0)
    }
}