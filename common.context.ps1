$WorkingDir = ([IO.DirectoryInfo](Get-Location).Path)

$Script:Context = @{
    "hostname" =    [string](Get-DockerHostname)
    "tenant" =      (Get-Content -Path (Join-Path -Path $WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json).TENANT
    "path"= @{
        "workingDir" =  $WorkingDir
        "secretsDir" =  [IO.DirectoryInfo](Join-Path -Path $WorkingDir -ChildPath "include")
        "dataDir" =     [IO.DirectoryInfo](Join-Path -Path $WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $WorkingDir.BaseName))
        "secretsDir" =  [IO.DirectoryInfo](Join-Path -Path $WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $WorkingDir.BaseName, ".secrets"))
        
        "composeFile" = [IO.FileInfo](Join-Path -Path $WorkingDir -ChildPath "compose.yaml")
        "dotEnvFile" =  [IO.FileInfo](Join-Path -Path $WorkingDir -ChildPath ".env")
        "configFile" =  [IO.FileInfo](Join-Path -Path $WorkingDir.Parent -ChildPath "" -AdditionalChildPath @(".config", "docker.config.json"))
    }
    "docker" = @{
        "projectname"=  [string]($WorkingDir.BaseName)
        "PUID" =        [int]568
        "PGID" =        [int]568
        "dockerPGID" =  [int](Get-DockerPGID)
    }
}
