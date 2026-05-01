
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
rm -rf * \
 && git clone https://github.com/bonzosoft/bootstrap.git \
 && echo '#!/usr/bin/env bash' > run \
 && echo 'docker compose -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1' >> run \
 && chmod +x run
````

Si estamos en pruebas, podemos indicar el branch:
````bash
rm -rf * \
 && git clone --branch --single-branch "pwsh" https://github.com/bonzosoft/bootstrap.git \
 && echo '#!/usr/bin/env bash' > run \
 && echo 'docker compose -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1' >> run \
 && chmod +x run
````

## Uso

````bash
./run -Menu
````

### Menu

#### Docker Compose
````bash
docker compose -f ./bootstrap/compose.yaml run --rm worker pwsh ./bootstrap/run.ps1 -Menu
````

#### Docker CLI
````bash
docker run -it --rm -w "$(pwd)" -v "/mnt:/mnt" -v "$(pwd)/.config/gh:/root/.config/gh" -v "/var/run/docker.sock:/var/run/docker.sock" ghcr.io/bonzosoft/pwsh:latest pwsh ./bootstrap/run.ps1 -Menu
````