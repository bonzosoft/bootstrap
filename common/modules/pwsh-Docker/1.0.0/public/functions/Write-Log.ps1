function Write-Log {
    [CmdletBinding(PositionalBinding=$true)]
    [OutputType([void])]

    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERRO", "SUCC")]
        [string]$Level,

        [Parameter()]
        [ValidateNotNull()]
        [string]$Message
    )

    [string]$displayeMessage = ""
    [string]$timestamp = $(Get-Date -Format "yyyy-MM-dd\THH:mm:ss.fffK")
    [string]$separator = "  "
    [int[]]$position = @()
    [hashtable]$COLOR = @{
        RED     = "`e[31m"
        GREEN   = "`e[32m"
        YELLOW  = "`e[33m"
        BLUE    = "`e[34m"
        MAGENTA = "`e[35m"
        CYAN    = "`e[36m"
        RESET   = "`e[0m"
    }

    if ($Message) {
        $displayeMessage = $timestamp
        switch ($Level) {
            "INFO" {
                $displayeMessage += $separator + "[" + $COLOR.CYAN + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
            "WARN" {
                $displayeMessage += $separator + "[" + $COLOR.YELLOW + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
            "ERRO" {
                $displayeMessage += $separator + "[" + $COLOR.RED + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
            "SUCC" {
                $displayeMessage += $separator + "[" + $COLOR.GREEN + $Level.ToUpper() + $COLOR.RESET + "]" + $separator
            }
        }
        $displayeMessage += $Message
    }
    else {
        try {
            $position = $Host.UI.RawUI.CursorPosition
            $position.X = ($timestamp.Length + 3)
            $position.Y = ($position.Y - 1)
            $Host.UI.RawUI.CursorPosition = $position
        }
        catch {
            throw "Unable to configurate screen position."
        }

        switch ($Level) {
            "SUCC" {
                $displayeMessage = $COLOR.GREEN + " OK " + $COLOR.RESET
            }
            "ERRO" {
                $displayeMessage = $COLOR.RED + "FAIL" + $COLOR.RESET
            }
            default {
                throw "Parameter 'Message' is mandatory for option level '$Level'."
            }
        }
    }
    Write-Information $displayeMessage -InformationAction Continue
}