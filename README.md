
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

### 1.- Descarga de archivos
Ejecutar:
````bash
   rm -rf ./bootstrap \
&& git clone --branch "main" --single-branch https://github.com/bonzosoft/bootstrap.git \
&& ln -snf "${PWD}/bootstrap/bootstrap.sh" "${PWD}/install" \
&& chmod +x "${PWD}/install"
````

### 2.- Ejecución del helper
Ejecutar:
````bash
./install
````

### 3.- Inicio de sesión en Github
Seleccionar:
````
Login
````
Y seguir las instrucciones.

### 4.- Selección del Realm
Seleccionar:
````
Set Realm
````
Y seguir las instrucciones. En AST seleccionar ``Production``.

#### 5.- Instalar el programa
En el servidor principal seleccionar:
````
Komodo Core pull
````
En el servidor secundario seleccionar:
````
Komodo Periphery pull
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
