#requires -Version 5
Set-StrictMode -Version Latest

function Split-LineInternal {
    [CmdletBinding()]
    [OutputType([string[]])]
    Param (
        [string]$InputObject
    )

    $lines = $InputObject -split "\n", 2
    $first = $lines[0]
    $second = ""
    if (1 -lt $lines.Count) {
        $second = $lines[1]
    }

    return ($first, $second)
}
