## Inicio del script
````bash
docker run --rm -w "$(pwd)" -v "/mnt:/mnt" -e TERM=dumb ghcr.io/bonzosoft/pwsh:latest pwsh -File ./onclone.ps1
````

## GIT Idempotente sin cambiar de directorio
````bash
if (Test-Path "repo/.git") {
    git -C repo pull
} else {
    git clone https://github.com/usuario/repo.git repo
}
````

## Powershell

### Descargar archivo
````pwsh
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/usuario/repositorio/main/archivo.txt" -OutFile "archivo.txt"
````

### Directorio de trabajo
````pwsh
Get-Location
````

### Ruta al script actual
````pwsh
$PSCommandPath
````

### Ruta al directorio del script actual
````pwsh
$PSScriptRoot
````

### Variables de entorno

#### Sesión únicamente
````pwsh
[Environment]::SetEnvironmentVariable("DB_HOST", "localhost", "Process")
````

#### Persistente para el usuario
````pwsh
[Environment]::SetEnvironmentVariable("DB_HOST", "localhost", "User")
````