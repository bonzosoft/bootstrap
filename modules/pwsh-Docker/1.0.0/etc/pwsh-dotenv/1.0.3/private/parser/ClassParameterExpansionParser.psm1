using module ./EnumParameterExpansionOpTypes.psm1
using module ./ClassSimpleVariableExpression.psm1
using module ./ClassParameterExpansion.psm1

#requires -Version 5
Set-StrictMode -Version Latest

class ParameterExpansionParser {

    [regex]$PREFIX_PATTERN = [regex]'\G(?:[\\$}]|[^\\$}]+)'

    [string]$str
    [ParameterExpansion]$expansion

    ParameterExpansionParser([string]$str) {
        $this.str = $str
        $this.expansion = [ParameterExpansion]::new()
    }

    [ParameterExpansion]Parse() {
        [void]$this._Parse(0, 0)
        return $this.expansion
    }

    hidden [int]_Parse([int]$parser_start_index, [int] $nested_levels) {
        $m = $this.NextMatch($parser_start_index)
        for (; ; ) {
            if (($null -eq $m) -or (-not $m.Success)) {
                if (0 -lt $nested_levels) {
                    # } closing curly brace not found
                    return -1
                }
                break
            }

            if ($m.Value.StartsWith('}') -and (0 -lt $nested_levels) ) {
                # } closing curly brace
                return ($m.Index + $m.Length)
            }
            if ($m.Value.StartsWith('\')) {
                # escape
                if(($m.Index + 1) -lt $this.str.Length){
                    $this.expansion.AddEscapeString(($this.str[$m.Index..($m.Index + 1)] -join ""))
                    $m = $this.NextMatch($m.Index + 2)
                }else{
                    $this.expansion.AddEscapeString(($this.str[$m.Index..($m.Index)] -join ""))
                    $m = $this.NextMatch($m.Index + 1)
                }
            }
            elseif ($m.Value.StartsWith('$')) {
                # variable
                $next_index = $this.ParseParameterExpansion($m.Index, $nested_levels)
                $m = $this.NextMatch($next_index)
            }
            else {
                $this.expansion.AddStringLiteral($m.Value)
                $m = $m.NextMatch()
            }
        }
        return $this.str.Length
    }

    hidden [System.Text.RegularExpressions.Match]NextMatch([int]$index) {
        if ($index -le $this.str.Length) {
            return $this.PREFIX_PATTERN.Match($this.str, $index)
        }
        return $null
    }

    hidden [int]ParseParameterExpansion([int]$start_index, [int] $nested_levels) {
        if ($this.str.IndexOf('${', $start_index, 2) -eq $start_index) {
            # ${variable} format
            return $this.ParseCurlyBracesVariableExpansion($start_index, $nested_levels)
        }
        $m = ([regex]'\G\$(?<variable_name>[a-zA-Z_][a-zA-Z0-9_]*)').Match($this.str, $start_index)
        if ($m.Success) {
            # $variable format
            $this.expansion.AddSimpleVariable($m.Groups["variable_name"].Value, $m.Value)
            return ($m.Index + $m.Length)
        }
        $this.expansion.AddStringLiteral($this.str[$start_index])
        return $start_index + 1
    }

    hidden [int]ParseCurlyBracesVariableExpansion([int]$start_index, [int] $nested_levels) {
        $m = ([regex]'\G\${(?<variable_name>[a-zA-Z_][a-zA-Z0-9_]*)[:}]').Match($this.str, $start_index)
        if (-not $m.Success) {
            Write-Warning -Message "$($this.GetType()): bad substitution: $($this.str.Substring($start_index))"
            return $this.str.Length
        }

        $variable_name = $m.Groups["variable_name"].Value
        if ($m.Value.EndsWith('}')) {
            # ${variable} format
            $this.expansion.AddCurlyBracesVariable([SimpleVariableExpression]::new($variable_name, $m.Value), $null, [ParameterExpansionOpTypes]::BASIC_FORM, $m.Value)
            return ($m.Index + $m.Length)
        }
        if ($m.Value.EndsWith(':')) {
            # ${variable: format
            if ("-" -eq $this.str[($m.Index + $m.Length)]) {
                # ${variable:- format

                $p = [ParameterExpansionParser]::new($this.str)
                $next_index = $p._Parse($start_index + $m.Length + 1, $nested_levels + 1)
                if ($next_index -lt 0) {
                    Write-Warning -Message "$($this.GetType()): bad substitution: $($this.str.Substring($start_index))"
                    return $this.str.Length
                }
                $word = $p.expansion
                $source = $this.str.Substring($start_index, $next_index - $start_index)
                $param = [SimpleVariableExpression]::new($variable_name, $source);
                $this.expansion.AddCurlyBracesVariable($param, $word, [ParameterExpansionOpTypes]::PARAMETER_IS_UNSET_OR_NULL, $source)
                return $next_index
            }
        }
        Write-Warning -Message "$($this.GetType()): bad substitution: $($this.str.Substring($start_index))"
        return $this.str.Length
    }

}
