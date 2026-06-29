using module ./ClassEvaluateContext.psm1
using module ./ClassExpression.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class SingleQuoteStringExpression : Expression {
    [string]$value
    SingleQuoteStringExpression([string]$value) {
        $this.value = $value
    }
    [string]Evaluate([EvaluateContext]$context) {
        return [regex]::Replace($this.value, "\\\\|\\'", {
                Param([System.Text.RegularExpressions.Match]$match)
                $val = ""
                switch -CaseSensitive ($match.Value) {
                    "\\" {
                        $val = "\"
                    }
                    "\'" {
                        $val = "'"
                    }
                }
                if ("" -eq $val) {
                    Write-Warning -Message ("unsupported escape " + $this.value)
                    if ('\' -eq $this.value) {
                        $val = '\'
                    }
                    elseif ($this.value.StartsWith('\')) {
                        $val = $this.value.Substring(1)
                    }
                    else {
                        $val = $this.value
                    }
                }
                return $val
            })
    }
    [string]ToString() {
        return $this.value
    }
}
