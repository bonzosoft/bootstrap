#requires -Version 5
Set-StrictMode -Version Latest

function Initialize-Internal(){
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Scope='Function')]
    Param()

    if(-not (Test-Path Microsoft.PowerShell.Core\Variable::IsCoreCLR)){
        $IsCoreCLR = $false;
    }
    if(-not (Test-Path Microsoft.PowerShell.Core\Variable::IsWindows)){
        $IsWindows = $true;
    }

    Set-Variable -Scope script -option None EnvDriveName        "Env"
    Set-Variable -Scope script -option None IsCaseSensitive     ($IsCoreCLR -and (-not $IsWindows))
    Set-Variable -Scope script -option None REG_START           ("(?:\A|^)")
    Set-Variable -Scope script -option None REG_END             ("(?:\z|[\r\n]+)")
    Set-Variable -Scope script -option None REG_SPACE           ("(?:[ \t\r\n\f\v])")
    Set-Variable -Scope script -option None REG_KEY             ("[a-zA-Z_][a-zA-Z0-9_]*")

    if($IsCaseSensitive){
        Set-Variable -Scope script -option None StringComparer      ([StringComparer]::Ordinal)
    }else{
        Set-Variable -Scope script -option None StringComparer      ([StringComparer]::OrdinalIgnoreCase)
    }

}
