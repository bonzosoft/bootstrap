function Set-DockerContext {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([void],      ParameterSetName = "Default")]
    [OutputType([hashtable], ParameterSetName = "PassThru")]

    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [object]$Value,

        [Parameter(Mandatory, ParameterSetName = "PassThru")]
        [switch]$PassThru
    )

    begin {

    }

    process {
        $Script:Context | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }

    end {
        if ($PassThru.IsPresent) {
            Write-Output -InputObject $Script:Context
        }
    }
}