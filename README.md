# Scripting
Scripts disponibles:
 - onclone.ps1
 - onpull.ps1
 - predeploy.ps1
 - postdeploy.ps1

Una vez instalado el sistema (bootstrap), para ejecutar los scripts usar:
````bash
../cmd ./onpull.ps1
````
Se puede mostrar información del desarrollo con:
````bash
../cmd ./onpull.ps1 -InformationAction Continue
````

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
