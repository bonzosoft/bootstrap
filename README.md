
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
Descarga de los archivos necesarios:
````bash
rm -rf ./bootstrap \
 && git clone https://github.com/bonzosoft/bootstrap.git \
 && echo '#!/usr/bin/env bash' > run \
 && echo 'docker run -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1' >> bootstrap \
 && chmod +x run
````


````bash
rm -rf ./bootstrap \
  && git clone https://github.com/bonzosoft/bootstrap.git \
  && ln -snf "${PWD}/bootstrap/bootstrap.sh" "${PWD}/bootstrap.sh" \
  && chmod +x "${PWD}/bootstrap.sh"
````




Si estamos en pruebas, podemos indicar el branch:
````bash
rm -rf ./bootstrap \
 && git clone --branch --single-branch "pwsh" https://github.com/bonzosoft/bootstrap.git \
 && echo '#!/usr/bin/env bash' > run \
 && echo 'docker compose -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1' >> run \
 && chmod +x run
````

## Uso

### Script
Para ejecutar el modo TUI:
````bash
./run
````
o actualizando:
````bash
pushd ./bootstrap && git pull && popd && ./run
````

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