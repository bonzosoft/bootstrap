using module ./ClassEvaluateContext.psm1
using module ./ClassExpression.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class StringLiteralExpression : Expression {
    [string]$value
    StringLiteralExpression([string]$value) {
        $this.value = $value
    }
    [string]Evaluate([EvaluateContext]$context) {
        return $this.value
    }
}
