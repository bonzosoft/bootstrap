$WorkingDir = ([IO.DirectoryInfo](Get-Location).Path)
Write-Host "pasa"
$Script:Context = @{
    "general" = @{
        "hostname" =    [string](Get-DockerHostname)
        "tenant" =      (Get-Content -Path (Join-Path -Path $Script:Context.WorkingDir.Parent -ChildPath ".config" -AdditionalChildPath "docker.config.json") | ConvertFrom-Json).TENANT
    }
    "path"= @{
        "workingDir" =  $WorkingDir
        "dataDir" =     [IO.DirectoryInfo](Join-Path -Path $WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $WorkingDir.BaseName))
        "secretsDir" =  [IO.DirectoryInfo](Join-Path -Path $WorkingDir.Parent.Parent -ChildPath "" -AdditionalChildPath @("state", $WorkingDir.BaseName, ".secrets"))
        "composeFile" = [IO.FileInfo](Join-Path -Path $WorkingDir -ChildPath "compose.yaml")
        "dotEnvFile" =  [IO.FileInfo](Join-Path -Path $WorkingDir -ChildPath ".env")
        "configFile" =  [IO.FileInfo](Join-Path -Path $WorkingDir.Parent -ChildPath "" -AdditionalChildPath @(".config", "docker.config.json"))
    }
    "docker" = @{
        "projectname"=  [string]($WorkingDir.BaseName)
        "dockerPGID" =  [int](Get-DockerPGID)
    }
}
Write-Host "no pasa"
$Context