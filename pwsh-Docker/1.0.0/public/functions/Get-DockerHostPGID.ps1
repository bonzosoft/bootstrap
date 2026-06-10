function Get-DockerHostPGID {
    [CmdletBinding()]
    [OutputType([int])]

    param ()

    begin {
        [string[]]$dockerGroup = Get-Content "/host/etc/group" | Where-Object {$PSItem -match "^docker:"}
    }

    end {
        if ($dockerGroup.Count -lt 1) {
            throw "No 'docker' group was found on host. Check your Docker installation."
        }
        elseif ($dockerGroup.Count -gt 1) {
            throw "More thant one 'docker' group was found on host."
        }
        else {
            Write-Output -InputObject ([int]($dockerGroup.Split(":")[2]))
        }
    }
}