
# Bootstrap

## Prerrequisitos
Se debe tener creada la carpeta ``/mnt`` que será la base de la infraestructura.

## Instalación
Descarga de los archivos necesarios:
````bash
git clone --branch pwsh https://github.com/bonzosoft/bootstrap.git
````

## Uso

### Menu

#### Docker Compose
````bash
docker compose run --rm worker pwsh ./bootstrap/run.ps1
````

#### Docker CLI
````bash
docker run -it --rm -w "$(pwd)" -v "/mnt:/mnt" -v "$(pwd)/.config/gh:/root/.config/gh" -v "/var/run/docker.sock:/var/run/docker.sock" ghcr.io/bonzosoft/pwsh:latest pwsh ./bootstrap/run.ps1 -Menu
````

### OnPull
````bash
docker run --rm -w "$(pwd)" -v "/mnt:/mnt" -e TERM=dumb ghcr.io/bonzosoft/pwsh:latest pwsh -File ./onclone.ps1 -Realm production
````

## Depuración
````pwsh
Import-Module ./common/posh-Docker
$compose = Get-DockerCompose -Path ./compose.yaml
Get-DockerVolumes -Data $compose
````