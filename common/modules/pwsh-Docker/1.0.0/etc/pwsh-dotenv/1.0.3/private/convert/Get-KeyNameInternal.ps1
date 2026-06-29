#requires -Version 5
Set-StrictMode -Version Latest

function Get-KeyNameInternal(){
    [CmdletBinding()]
    [OutputType([string[]])]
    Param (
        [string]$str
    )
    if ($str -notmatch "${script:REG_START}(?:export${script:REG_SPACE}+)?(?<key_name>\w+)${script:REG_SPACE}*=") {
        return ("", $str)
    }
    $key = $Matches["key_name"];
    $tail = $str.Substring($Matches[0].Length)
    return ($key, $tail)
}
