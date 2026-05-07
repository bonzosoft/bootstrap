#requires -Version 5
Set-StrictMode -Version Latest

enum ParameterExpansionOpTypes {
    # NOP
    NOP
    # ${parameter}
    BASIC_FORM
    # ${parameter:-word}
    PARAMETER_IS_UNSET_OR_NULL
}

