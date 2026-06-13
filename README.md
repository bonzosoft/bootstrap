
# Instalación

## Prerequisitos

Antes de hacer login, hay que instalar la herramienta Github-cli.

### Instalar

* Debian
````bash
apt update
apt install gh
````

* Alpine
````bash
apk update
apk add github-cli
````

### Verificar

````bash
gh --version
````

### Autentificar

````bash
gh auth login --device
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











## Linea de comandos

Los scripts disponibles son:
 - onclone.ps1
 - onpull.ps1
 - predeploy.ps1
 - postdeploy.ps1

Una vez instalado el sistema (bootstrap), para ejecutar los scripts se puede usar:

````bash
../cmd pwsh -File ./onpull.ps1
````


## Estructura de directorios


### Información general

Branch Connector        ├   U+251C: BOX DRAWINGS LIGHT VERTICAL AND RIGHT
Leaf Connector          └   U+2514: BOX DRAWINGS LIGHT UP AND RIGHT
Horizontal Connector    ─   U+2500: BOX DRAWINGS LIGHT HORIZONTAL
Vertical Connector      │   U+2502: BOX DRAWINGS LIGHT VERTICAL


### Estructura

/mnt/tank0/apps/
├──  infra/
│    ├── .config/
│    │   ├── gh/
│    │   └── host/
│    │       └── config.json
│    ├── bootstrap/
│    │   └── install.sh
│    ├── common/
│    │   ├── tenants/
│    │   │   ├── ast.json
│    │   │   └── bonzosoft.json
│    │   └── cmd.sh
│    ├── project/
│    │   ├── config/
│    │   │   └── conifg.ini
│    │   ├── .env
│    │   ├── .env.app
│    │   ├── compose.global.yaml
│    │   ├── compose.yaml
│    │   └── onpull.ps1
│    ├── cmd
│    └── install
├── state/
│    └── *projectname*/
│        ├── .secrets/
│        ├── app/
│        ├── cache/
│        ├── certs/
│        ├── db/
│        ├── dbbackup/
│        ├── dockerproxy/
│        └── webproxy/
└── storage/
     └── *projectname*/


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
