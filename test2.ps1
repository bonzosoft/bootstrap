[IO.FileInfo]$var=$PSCommandPath
[IO.FileInfo]$Local:localvar=$PSCommandPath

Write-Host "test2-1: $var"
Write-Host "test2-1local: $Local:localvar"

[IO.FileInfo]$PSCommandPath | Format-List *