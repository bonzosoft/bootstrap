
# Bootstrap

## Prerrequisitos
Se debe tener creada la carpeta ``/mnt/tank0/apps`` que será la base de la infraestructura.

## Instalación
Descarga de los archivos necesarios desde bash:
````bash
wget -qO bootstrap https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1 && wget -qO compose.yaml https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml
````
o desde Powershell:
````pwsh
docker run -it --rm -v /mnt:/mnt -w $(pwd) ghcr.io/bonzosoft/pwsh:latest pwsh -Command 'Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/bootstrap.ps1" -OutFile "bootstrap";
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/pwsh/compose.yaml" -OutFile "compose.yaml"'
````

## Uso

### Menu
````bash
docker run -it -rm -v /mnt:/mnt -v $(pwd)/.config/gh:/root/.config/gh -v /var/run/docker.sock:/var/run/docker.sock -w $(pwd) ghcr.io/bonzosoft/pwsh:7.6.0 pwsh ./bootstrap -Action menu
````
