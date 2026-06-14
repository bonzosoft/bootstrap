#requires -Version 5
Set-StrictMode -Version Latest

class EvaluateContext {

    [scriptblock]$variable_getter

    EvaluateContext([scriptblock]$variable_getter) {
        $this.variable_getter = $variable_getter
    }

    [string]GetVariable([string]$variable_name) {
        return & $this.variable_getter $variable_name
    }
}
