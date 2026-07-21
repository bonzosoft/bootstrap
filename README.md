
# Bootstrap

## 1. Prerrequisitos

Ninguno.
El script creara el arbol de directorios preconfigurado.
El script descargará todo el contenido necesrio del repositorio configurado.

## 2. Instalación

Para realizar el bootstrap de la instalación del entorno de Docker, ejecutar:

````bash
docker run --rm -it -v ${PWD}:${PWD}:rw -w ${PWD} ghcr.io/bonzosoft/pwsh pwsh -NoLogo -Command '& {$repository = "bootstrap"; $branch = "bw"; if (Test-Path -Path ./$repository){Remove-Item -Path ./$repository -Recurse -Force}; git clone --branch $branch https://github.com/bonzosoft/$repository; & ./$repository/$repository.ps1}'
````

## 3. Configuración
Para configurar el entorno, ejecutar:
````bash
./install
````

## 4. Ejecución de pwsh

Para usar el contenedor de ``pwsh`` se puede:

### 1. Ejecutar un comando arbitrario con:

````
./cmd Write-Host "Hola Mundo."
````

### 2. Iniciar la consola con:
````bash
./cmd
````