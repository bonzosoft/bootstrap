#requires -Version 5
Set-StrictMode -Version Latest

function New-HashTbaleInternal{
    [CmdletBinding()]
    [OutputType([System.Collections.IDictionary])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function')]
    Param ()
    New-Object System.Collections.Specialized.OrderedDictionary ($script:StringComparer)
}
