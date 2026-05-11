function ConvertTo-UnixFileMode {
    [CmdletBinding()]
    [OutputType([IO.UnixFileMode])]
    
    param(
        [Parameter(Mandatory)]
        [int]$Octal
    )

    begin {
        <#
        None            0	    No permissions.
        
        OtherExecute    1	    Execute permission for others.
        OtherWrite  	2	    Write permission for others.
        OtherRead	    4	    Read permission for others.

        GroupExecute	8	    Execute permission for group.
        GroupWrite	    16	    Write permission for group.
        GroupRead	    32	    Read permission for group.

        UserExecute	    64	    Execute permission for owner.
        UserWrite	    128	    Write permission for owner.
        UserRead	    256	    Read permission for owner.

        StickyBit	    512	    Sticky bit permission.
        SetGroup	    1024    Set group permission.
        SetUser	        2048    Set user permission.
        #>
        [IO.UnixFileMode]$intMode = [Convert]::ToInt32($Octal, 8)
    }
    
    end {
        Write-Output -InputObject ([IO.UnixFileMode]$intMode)
    }
}

<#
[IO.UnixFileMode]$directoryPermission = ConvertTo-UnixFileMode -Octal 0740
[IO.UnixFileMode]$filePermission = $directoryPermission - ([IO.UnixFileMode]::UserExecute + [IO.UnixFileMode]::GroupExecute + [IO.UnixFileMode]::OtherExecute)

$directoryPermission
#$filePermission       

$filePermission = $directoryPermission
if ($directoryPermission -band [IO.UnixFileMode]::UserExecute) {
    $filePermission -= [IO.UnixFileMode]::UserExecute
}
$filePermission
#>