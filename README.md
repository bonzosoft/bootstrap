
# Bootstrap

## 1.- Prerrequisitos

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
|  |- komodo-core/
|     |- app/
|     |- db/
|     |- dbwrapper/
|     |- proxy/
|- storage/
````

## 2.- Instalación

Para realizar el bootstrap de la instalación del entorno de Docker, ejecutar:

````bash
export BRANCH="main" && wget -qO ${PWD}/bootstrap/bootstrap.ps1 https://raw.githubusercontent.com/bonzosoft/bootstrap/$BRANCH/bootstrap.ps1 && docker run --rm -it -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -NoProfile -File ${PWD}/bootstrap.ps1 && rm ${PWD}/bootstrap.ps1
````

````bash
docker run --rm -it -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -Command '& {$branch = "main"; Invoke-RestMethod -Uri "https://raw.githubusercontent.com/bonzosoft/bootstrap/$branch/bootstrap.ps1" -OutFile ./bootstrap.ps1; & ./bootstrap.ps1; Remove-Item -Path ./bootstrap.ps1}'
````

## 3.- Configuración
Para configurar el entorno, ejecutar:
````bash
./install
````

### 4.- Ejecución de pwsh

Para usar el contenedor de ``pwsh`` se puede ejecutar un comando aleatorio con:

````
./cmd Write-Host "Hola Mundo."
````

o iniciar la consola con:
````bash
./cmd
````