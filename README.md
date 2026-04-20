## Inicio del script
````bash
docker run --rm -w "$(pwd)" -v "/mnt:/mnt" -e TERM=dumb ghcr.io/bonzosoft/pwsh:latest pwsh -File ./onclone.ps1 -Realm production
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

## Obtener el usuario Docker

### Opcion 1
Montar
````yaml
volumes:
  - /etc/group:/host/etc/group:ro
````
y
usar:
````bash
grep '^docker:' /host/etc/group | cut -d: -f3
````
### Opcion 2
Montar el socket:
````yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
````
y ejecutar:
````bash
stat -c '%g' /var/run/docker.sock
````
### Opcion 3
Pasarlo desde el host como parametro:

$DockerGID = (getent group docker | cut -d: -f3)
docker run -e HOST_DOCKER_GID=$DockerGID ...