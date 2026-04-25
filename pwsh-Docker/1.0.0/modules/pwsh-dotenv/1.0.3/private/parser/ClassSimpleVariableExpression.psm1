using module ./ClassEvaluateContext.psm1
using module ./ClassExpression.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class SimpleVariableExpression : Expression {
    [string]$variable_name
    [string]$source
    SimpleVariableExpression([string]$variable_name, [string]$source) {
        $this.variable_name = $variable_name
        $this.source = $source
    }
    [string]Evaluate([EvaluateContext]$context) {
        if ("" -eq $this.variable_name) {
            $val = ""
        }
        else {
            $val = $context.GetVariable($this.variable_name)
        }
        Write-Debug -Message "$($this.GetType()): ${this} => ${val}"
        return $val
    }
    [string]ToString() {
        return $this.source
    }
}

