#requires -Version 5
Set-StrictMode -Version Latest

function Get-SimpleValueInternal {
    [CmdletBinding()]
    [OutputType([Object[]])]
    Param (
        [string]$InputObject
    )

    # split newline
    $value, $tail = Split-LineInternal $InputObject
    # split comment
    $value = ($value -split "#", 2)[0].Trim()
    # $value = ($value -split "[ \t\f\v]+#", 2)[0].Trim()

    $env_entry = [EnvEntry]::new($value, [EnumQuoteTypes]::UNQUOTED)

    return ($env_entry, $tail);
}
