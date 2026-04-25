#requires -Version 5
Set-StrictMode -Version Latest

Set-Variable -Scope script -option None ModuleRoot $PSScriptRoot

(Get-ChildItem -Path "$ModuleRoot/private/*.ps1" -Recurse -ErrorAction SilentlyContinue ) | Sort-Object DirectoryName,Name | ForEach-Object {
    if(-not $_.Name.StartsWith("Klass")){
        . $_.Fullname
    }
}


$export_func = @()
(Get-ChildItem -Path "$ModuleRoot/public/*.ps1" -Recurse -ErrorAction SilentlyContinue ) | Sort-Object DirectoryName,Name | ForEach-Object {
    . $_.Fullname
    $export_func += ($_.Name -replace "\.ps1$","")
}

Initialize-Internal

Export-ModuleMember -Function @($export_func) -Alias "*"
