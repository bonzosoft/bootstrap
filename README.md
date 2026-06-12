
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
   clear \
&& BRANCH="pruebas"
&& rm -rf "${PWD}/bootstrap" \
&& git clone --branch ${BRANCH} --single-branch https://github.com/bonzosoft/bootstrap.git \
&& ln -snf "${PWD}/bootstrap/bootstrap.sh" "${PWD}/install" \
&& chmod +x "${PWD}/install"
&& rm -rf "${PWD}/common" \
&& git clone --branch ${BRANCH} --single-branch https://github.com/bonzosoft/common.git \
&& ln -snf "${PWD}/common/cmd.sh" "${PWD}/cmd" \
&& chmod +x "${PWD}/cmd"
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

### Reset
Para resetear todo:
````bash
rm -rf /mnt/tank0/apps/infra/* && rm -rf /mnt/tank0/apps/state
````

### Docker CLI
Para ejecutar el menú usando Docker CLI:
````bash
docker run \
    -it \
    -v /etc:/host/etc:ro \
    -v /mnt/tank0/apps:/mnt/tank0/apps:rw \
    -w ${PWD} \
    ghcr.io/bonzosoft/pwsh pwsh
````


