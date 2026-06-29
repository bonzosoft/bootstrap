#requires -Version 5
Set-StrictMode -Version Latest

function Split-KeyValueInternal {
    [CmdletBinding()]
    [OutputType([Object[]])]
    Param (
        [string]$InputObject
    )

    $key, $tail = Get-KeyNameInternal $InputObject
    if ("" -eq $key) {
        $first, $tail = Split-LineInternal $tail
        Write-Warning -Message "invalid line:$first"
        return ($null, $tail)
    }

    $env_entry, $tail = Get-ValueInternal $tail

    if ($key -notmatch "${script:REG_START}${script:REG_KEY}${script:REG_END}") {
        Write-Error "unexpected character `"$key`" in variable name near $InputObject" -Category ParserError
        return ($null, $tail)
    }

    $env_entry.Name = $key;

    return ($env_entry, $tail)
}
