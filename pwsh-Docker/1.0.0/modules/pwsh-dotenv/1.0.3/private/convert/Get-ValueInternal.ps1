#requires -Version 5
Set-StrictMode -Version Latest

function Get-ValueInternal {
    [CmdletBinding()]
    [OutputType([Object[]])]
    Param (
        [string]$InputObject
    )

    $str = Remove-SpaceInternal -InputObject $InputObject -TrimStart

    if ("" -eq $str) {
        return ([EnvEntry]::new("", [EnumQuoteTypes]::UNQUOTED), "");
    }
    $prefix = Get-QuotePrefixInternal $str
    if ("" -eq $prefix) {
        return (Get-SimpleValueInternal $str);
    }
    else {
        return (Get-QuotedValueInternal $str $prefix);
    }
}
