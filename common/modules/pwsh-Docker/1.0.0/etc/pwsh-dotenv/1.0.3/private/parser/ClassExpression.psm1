using module ./ClassEvaluateContext.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class Expression {
    [string]Evaluate([EvaluateContext]$context) {
        throw("Not Implement")
    }
}
