#requires -Version 5
Set-StrictMode -Version Latest

function Remove-SpaceInternal {
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    Param (
        [string]$InputObject,
        [switch]$TrimStart,
        [switch]$TrimEnd,
        [switch]$IncludeNewLine
    )

    if ($IncludeNewLine) {
        $removeChar = " `t`f`v`n`r"
    }
    else {
        $removeChar = " `t`f`v"
    }

    if ($TrimStart -and $TrimEnd) {
        $InputObject.Trim($removeChar)
    }
    elseif ($TrimStart) {
        $InputObject.TrimStart($removeChar)
    }
    elseif ($TrimEnd) {
        $InputObject.TrimEnd($removeChar)
    }
}
