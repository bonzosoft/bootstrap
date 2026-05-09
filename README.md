
# Bootstrap

## Prerrequisitos
La estructura de directorios recomendada es:
````
/mnt/tank0/apps
|- infra/
|  |- bootstrap/
|  |- common/
|  |- komodo-core/
|  |- komodo-periphery/
|  |- run
|- state/
   |- komodo-core/
      |- app/
      |- db/
      |- dbwrapper/
      |- proxy/
````

## Instalación

Descargar los archivos:

````bash
   rm -rf ./bootstrap \
&& git clone --branch "main" --single-branch https://github.com/bonzosoft/bootstrap.git \
&& ln -snf "${PWD}/bootstrap/bootstrap.sh" "${PWD}/install" \
&& chmod +x "${PWD}/install"
````

## Uso

### Script
Ejecutar el script en modo TUI:
````bash
./install
````
El primer paso es iniciar sesión en Github. Luego se puede instalar Komodo Core o Komodo Periphery.


## Uso avanzado

### Consola
Para ejecutar la consola de Powershell:
````bash
docker compose -f bootstrap/compose.yaml run --rm worker
````

#### Docker Compose
Para ejecutar el menú usando Docker Compose:
````bash
docker compose -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1 -Menu
````

#### Docker CLI
Para ejecutar el menú usando Docker CLI:
````bash
docker run -it --rm -w "$(pwd)" -v "/mnt:/mnt" -v "$(pwd)/.config/gh:/root/.config/gh" -v "/var/run/docker.sock:/var/run/docker.sock" ghcr.io/bonzosoft/pwsh:latest pwsh ./bootstrap/run.ps1 -Menu
````
### Reset
Para resetear todo:
````bash
rm -rf /mnt/tank0/apps/infra/* && rm -rf /mnt/tank0/apps/state
````



# backup
Descarga de los archivos necesarios:
````bash
rm -rf ./bootstrap \
 && git clone https://github.com/bonzosoft/bootstrap.git \
 && echo '#!/usr/bin/env bash' > run \
 && echo 'docker run -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1' >> bootstrap \
 && chmod +x run
````