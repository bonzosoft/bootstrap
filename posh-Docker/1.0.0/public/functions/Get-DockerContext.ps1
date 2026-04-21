function Get-DockerConext {
    #[IO.FileInfo]$Script:ENTRYSCRIPT      = $ENTRYSCRIPT
    #[IO.DirectoryInfo]$Script:WORKINGDIR  = $Script:ENTRYSCRIPT.Directory
    #[IO.DirectoryInfo]$Script:INCLUDEDIR  = Join-Path -Path $Script:WORKINGDIR -ChildPath "include"
    #[IO.DirectoryInfo]$Script:CONFIGDIR   = Join-Path -Path $Script:WORKINGDIR -ChildPath "config"
    #[IO.FileInfo]$Script:ENVFILE          = Join-Path -Path $Script:WORKINGDIR -ChildPath ".env"
    #[IO.FileInfo]$Script:COMPOSEFILE      = Join-Path -Path $Script:WORKINGDIR -ChildPath "compose.yaml"
    #[IO.DirectoryInfo]$Script:COMMONDIR   = $PSScriptRoot
    #[IO.FileInfo]$Script:COMMONENVFILE    = Join-Path -Path $Script:COMMONDIR -ChildPath ".env.common"
    #[IO.FileInfo]$Script:COMMONCONFIGFILE = Join-Path -Path $Script:COMMONDIR -ChildPath "../config.json"
    #[int]$Script:PUID = 568
    #[int]$Script:PGID = 568
    #[IO.DirectoryInfo]$Script:DATADIR     = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath "state"
    #[IO.DirectoryInfo]$Script:SECRETSDIR  = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath ".secrets"

    return [PSCustomObject]@{
        EntryScript = [IO.FileInfo]$ENTRYSCRIPT
        WorkingDir  = [IO.DirectoryInfo]$ENTRYSCRIPT.Directory
        IncludeDir  = [IO.DirectoryInfo](Join-Path -Path $Script:WORKINGDIR -ChildPath "include")
        ConfigDir   = [IO.DirectoryInfo](Join-Path -Path $Script:WORKINGDIR -ChildPath "config")
        EnvFile     = [IO.FileInfo](Join-Path -Path $Script:WORKINGDIR -ChildPath ".env")
        ComposeFile = [IO.FileInfo](Join-Path -Path $Script:WORKINGDIR -ChildPath "compose.yaml")
        CommonDir   = [IO.DirectoryInfo]$PSScriptRoot
        [int]$Script:PUID = 568
        [int]$Script:PGID = 568
        [IO.DirectoryInfo]$Script:DATADIR     = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath "state"
        [IO.DirectoryInfo]$Script:SECRETSDIR  = Join-Path -Path "/mnt/tank0/data" -ChildPath $ENTRYSCRIPT.Directory.BaseName -AdditionalChildPath ".secrets"
        
    
    }

}