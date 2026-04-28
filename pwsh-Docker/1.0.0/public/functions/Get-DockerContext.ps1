function Get-DockerContext {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param()

    return $Script:Env
}