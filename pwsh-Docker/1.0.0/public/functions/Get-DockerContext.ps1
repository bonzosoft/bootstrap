function Get-DockerContext {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param()

    end {
        return [PSCustomObject]$Script:Context
    }
}