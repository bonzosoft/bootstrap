#requires -Version 5
Set-StrictMode -Version Latest

function Get-QuotedValueInternal {
    [CmdletBinding()]
    [OutputType([Object[]])]
    Param (
        [string]$InputObject,
        [string]$Quote
    )

    $reg_quote = [regex]::Escape($Quote)

    $value_pattern = "${script:REG_START}${reg_quote}(?<value>(?:\\\\|\\${reg_quote}|[^${reg_quote}])*)${reg_quote}${script:REG_SPACE}*(?:#[^\r\n]+)?${script:REG_END}?"
    if ($InputObject -notmatch $value_pattern) {
        # broken string
        $first, $tail = Split-LineInternal $tail
        Write-Error "broken quoted value string ${first}" -Category ParserError
        return [EnvEntry]::new("", [EnumQuoteTypes]::UNQUOTED), $tail;
    }
    $value = $Matches["value"]
    $tail = $InputObject.Substring($Matches[0].Length)

    if (('"' -eq $Quote)) {
        $quote_type = [EnumQuoteTypes]::DOUBLE_QUOTED
    }
    elseif (("'" -eq $Quote)) {
        $quote_type = [EnumQuoteTypes]::SINGLE_QUOTED
    }
    else {
        $quote_type = [EnumQuoteTypes]::UNQUOTED
    }
    $env_entry = [EnvEntry]::new($value, $quote_type)

    return $env_entry, $tail;

}
