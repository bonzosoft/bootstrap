# Scripting
Scripts disponibles:
 - onclone.ps1
 - onpull.ps1
 - predeploy.ps1
 - postdeploy.ps1

Una vez instalado el sistema (bootstrap), para ejecutar los scripts usar:
````bash
../cmd ./onpull.ps1
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