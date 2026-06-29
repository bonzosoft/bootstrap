Clear-Host

(Measure-Command{
    ([IO.FileInfo]$PSCommandPath).Directory
}).TotalMilliseconds

(Measure-Command{
    $PSScriptRoot
}).TotalMilliseconds

(Measure-Command{
    ([IO.FileInfo]$PSCommandPath).Directory
}).TotalMilliseconds


(Measure-Command{
    Split-Path $PSScriptRoot -Parent
}).TotalMilliseconds

(Measure-Command{
    $PSCommandPath
}).TotalMilliseconds

(Measure-Command{
    $MyInvocation

}).TotalMilliseconds
