using module ./ClassEvaluateContext.psm1
using module ./ClassExpression.psm1
using module ./EnumParameterExpansionOpTypes.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class CurlyBracesVariableExpression : Expression {
    [Expression]$parameter
    [Expression]$word
    [ParameterExpansionOpTypes]$op
    [string]$source
    CurlyBracesVariableExpression([Expression]$parameter, [Expression]$word, [ParameterExpansionOpTypes]$op, [string]$source) {
        $this.parameter = $parameter
        $this.word = $word
        $this.op = $op
        $this.source = $source
    }
    [string]Evaluate([EvaluateContext]$context) {
        $val = ""
        switch ($this.op) {
            NOP {
                # NOP
            }
            BASIC_FORM {
                $val = $this.EvaluateBasicForm($context)
            }
            PARAMETER_IS_UNSET_OR_NULL {
                $val = $this.EvaluateParameterIsUnsetOrNull($context)
            }
        }
        Write-Debug -Message "$($this.GetType())($($this.op)): $($this.source) => ${val}"
        return $val
    }

    [string]ToString() {
        return $this.variable
    }

    hidden [string]EvaluateBasicForm([EvaluateContext]$context) {
        $val = & {
            $DebugPreference = '';
            if ($null -eq $this.parameter) {
                return ""
            }
            else {
                return $this.parameter.Evaluate($context)
            }
        }
        return $val
    }

    hidden [string]EvaluateParameterIsUnsetOrNull([EvaluateContext]$context) {
        $val = & {
            $DebugPreference = '';
            if ($null -eq $this.parameter) {
                return ""
            }
            else {
                return $this.parameter.Evaluate($context)
            }
        }
        if ($val -eq "") {
            if ($null -ne $this.word) {
                $val = $this.word.Evaluate($context)
            }
        }
        return $val
    }
}

