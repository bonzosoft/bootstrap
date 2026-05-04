function Import-DockerContext {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param()

    end {
        return [PSCustomObject]$Script:Context
    }
}