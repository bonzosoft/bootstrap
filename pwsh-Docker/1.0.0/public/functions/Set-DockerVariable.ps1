function Set-DockerVariable {
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType([void])]

    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]$Path = $Script:Context.Path.DotEnvFile,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Value,

        [Parameter()]
        [switch]$NoOverwrite, # evita sobrescribir el valor si existe

        [Parameter()]
        [switch]$NoAppend, # evita añadir el valor si no existe

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [string]$delimiter = "="
        [IO.FileInfo]$temporaryFile = $null
        [Collections.Generic.List[string]]$inputLines = @()
        [Collections.Generic.List[string]]$outputLines = @()
        [string]$currentName = ""
        [string]$currentValue = ""
        [string]$currentComment = ""
        [string]$currentLeftover = ""
        [bool]$keyFound = $false
        [hashtable]$matches = @{}
    }

    end {
        $inputLines = Get-Content -Path $Path -Encoding UTF8

        foreach ($line in $inputLines) {
            $currentName = ""
            $currentValue = ""
            $currentComment = ""
            $currentLeftover = ""
    
            if (($line -match '^\s*#') -or ($line -match '^\s*$')) { 
                # comment line starting with # or empty line
                $outputLines.Add($line)
                continue
            }
    
            if ($line -match '^\s*(?<name>.*?)\s*(?<delimiter>[=:])\s*(?<leftover>.*)$') {
                # ^                 beginning of line
                # \s*               zero or more whitespace characters
                # (?<name>.*?)      capturing group 'name' of zero or more characters (lazy match, captures as few characters as possible)
                # \s*               zero or more whitespace characters
                # ([=:])            capturing group of = or :
                # \s*               zero or more whitespace characters
                # (?<leftover>.*)   capturing group 'leftover' of zero or more characters (greedy, captures as many characters as possible)
                # $                 end of line
    
                if ($matches.ContainsKey("name")) {
                    $currentName = $matches.name
                }
                if ($matches.ContainsKey("leftover")) {
                    $currentLeftover = $matches.leftover
                }
    
                switch -Regex ($currentLeftover) {
                    '^[""''](?<value>[^""'']*)[""''](?:\s+(#)\s*(?<comment>.*))?$' {
                        ## quoted text
                        # ^                     beginning of line
                        # [""'']                " or '
                        # (?<value>[^""'']*)   capturing group 'value' zero or more characters different of " or '
                        # [""'']                " or '
                        # (?:...)?              non-capturing group, one or zero instances
                        # \s+                   one or more whitespace characters
                        # (#)                   capturing group of character #
                        # \s*                   zero or more whitespace characters
                        # (?<comment>.*)        capturing group of zero or more characters (greedy, captures as many characters as possible)
                        # $                     end of line
    
                        if ($matches.ContainsKey("value")) {
                            $currentValue = $matches.value
                        }
                        if ($matches.ContainsKey("comment")) {
                            $currentComment = $matches.comment
                        }
                        
                    }
                    '^(?<value>.*?)(?:\s+(#)\s*(?<comment>.*))?$' {
                        ## non-quoted text
                        # ^                 beginning of line
                        # (?<value>.*?)     capturing group 'value' of zero or more characters (lazy match, captures as few characters as possible)
                        # (?:...)?          non-capturing group, one or zero instances
                        # \s+               one or more whitespace characters
                        # (#)               capturing groupo of character #
                        # \s*               zero or more whitespace characters
                        # (?<comment>.*)    capturing group 'comment' of zero or more characters (greedy, captures as many characters as possible)
                        # $                 end of line
    
                        if ($matches.ContainsKey("value")) {
                            $currentValue = $matches.value
                        }
                        if ($matches.ContainsKey("comment")) {
                            $currentComment = $matches.comment
                        }
                    }
                    default {
                        throw "Invalid format: '$line'"
                    }
                }
            }
            else {
                throw "Invalid format: '$line'."
            }
    
            if ($currentName -eq $Name) {
                $keyFound = $true
    
                if (-not $NoOverwrite.IsPresent) {
                    $newLine = $currentName + $delimiter + $Value
                }
                else {
                    $newLine = $currentName + $delimiter + $currentValue
                } 
            }
            else {
                $newLine = $currentName + $delimiter + $currentValue 
            }
    
            if (-not [string]::IsNullOrWhiteSpace($currentComment)) {
                $newLine += " #" + $currentComment
            }
    
            $outputLines.Add($newLine)
        }
    
        if (-not $keyFound -and -not($NoAppend.IsPresent)) {
            $newLine = $Name + $delimiter + $Value 
            $outputLines.Add($newLine)
        }
       
        $temporaryFile = New-TemporaryFile
        Set-Content -Path $temporaryFile -Value $outputLines -Encoding UTF8
        if ($Path.LinkTarget) {
            Move-Item -Path $temporaryFile -Destination $Path.LinkTarget -Force
        }
        else {
            Move-Item -Path $temporaryFile -Destination $Path -Force
        }

        if ($PassThru.IsPresent) {
            Write-Output -InputObject $Path
        }
    }
}
