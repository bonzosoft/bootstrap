using module ./ClassEvaluateContext.psm1
using module ./ClassExpression.psm1
using module ./ClassStringLiteralExpression.psm1
using module ./ClassEscapeStringExpression.psm1
using module ./ClassSimpleVariableExpression.psm1
using module ./ClassCurlyBracesVariableExpression.psm1
using module ./EnumParameterExpansionOpTypes.psm1

#requires -Version 5
Set-StrictMode -Version Latest


class ParameterExpansion: Expression {

    [System.Collections.Generic.List[Expression]]$expressions

    ParameterExpansion() {
        $this.expressions = New-Object System.Collections.Generic.List[Expression]
    }

    [string]Evaluate([EvaluateContext]$context) {
        $buffer = New-Object System.Text.StringBuilder
        foreach ($expression in $this.expressions) {
            $buffer.Append($expression.Evaluate($context))
        }
        return $buffer.ToString()
    }

    [void]AddStringLiteral([string]$value) {
        $this.expressions.Add([StringLiteralExpression]::new($value))
    }
    [void]AddEscapeString([string]$value) {
        $this.expressions.Add([EscapeStringExpression]::new($value))
    }
    [void]AddSimpleVariable([string]$variable_name, [string]$source) {
        $this.expressions.Add([SimpleVariableExpression]::new($variable_name, $source))
    }
    [void]AddCurlyBracesVariable([Expression]$parameter, [Expression]$word, [ParameterExpansionOpTypes]$op, [string]$source) {
        $this.expressions.Add([CurlyBracesVariableExpression]::new($parameter, $word, $op, $source))
    }
}
