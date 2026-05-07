#requires -Version 5
Set-StrictMode -Version Latest

function Remove-LineCommentInternal {
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    Param(
        [string]$InputObject
    )
    Begin {

        function trimComment {
            param ($str)
            $str = $str.TrimStart()
            if ("" -eq $str) {
                return $str
            }
            if ("#" -ne $str[0]) {
                return $str
            }
            # split newline
            $first, $tail = Split-LineInternal $str
            return $tail
        }

    }
    Process {
        $str = $InputObject
        if ($null -eq $str) {
            $str = ""
        }
        $prev_str = $str
        while ($true) {
            $str = trimComment $str
            if ("" -eq $str) {
                return $str;
            }
            if ($prev_str -eq $str) {
                return $str;
            }
            $prev_str = $str
        }
    }
}
