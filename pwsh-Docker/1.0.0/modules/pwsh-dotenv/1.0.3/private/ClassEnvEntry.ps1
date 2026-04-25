using module ./parser/ClassParameterExpansionParser.psm1
using module ./parser/ClassEvaluateContext.psm1
using module ./parser/ClassSingleQuoteStringExpression.psm1
using module ./parser/EnumQuoteTypes.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class EnvEntry {

    [string]$Name = ""
    [string]$Value = ""
    [EnumQuoteTypes]$QuoteType

    EnvEntry([string]$Value, [EnumQuoteTypes]$QuoteType) {
        $this.Value = $Value
        $this.QuoteType = $QuoteType
    }

    [string]GetValue([scriptblock]$env_getter) {
        if ((-not ($this.Value.Contains('$') -or $this.Value.Contains('\')))) {
            return $this.Value
        }

        if ($this.QuoteType -eq [EnumQuoteTypes]::SINGLE_QUOTED) {
            $expansion = [SingleQuoteStringExpression]::new($this.Value)
        }
        else {
            $parser = [ParameterExpansionParser]::new($this.Value)
            $expansion = $parser.Parse()
        }

        $valuate_context = [EvaluateContext]::new({
                param($variable_name)
                return (& $env_getter ($variable_name))
            })

        return $expansion.Evaluate($valuate_context)

    }

    [string]ToString() {
        return $this.Name + "=" + $this.Value
    }

}
