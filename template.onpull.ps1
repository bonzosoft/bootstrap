#!/usr/bin/env pwsh

[CmdletBinding()]
[OutputType([void])]

param()

### BEGIN ######################################################################
Write-Information -Message "Loading script '$PSCommandPath'."
. (Get-Item -Path "../*/common.$(Split-Path -Path $PSCommandPath -Leaf)")


### VARIABLES ##################################################################
$serviceCodeName = "app"
#Set-DockerVariable -Name "dummy" -Value "dummy"




### SECRETS ####################################################################
if (-not (Test-DockerSubmodule)) {
    #Set-DockerSecret -Name "dummy" -Value "dummy"
    Grant-DockerPermission `
        -Path $Script:Context.SecretsDir `
        -PUID $Script:Context.Service.$serviceCodeName.PUID `
        -PGID $Script:Context.Service.$serviceCodeName.PGID `
        -Permission "0440" `
        -Recurse `
        -Force
}









### END ########################################################################
Write-Information -Message "Loaded script '$PSCommandPath'."
