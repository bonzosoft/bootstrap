## 🚀 Komodo Deployment Bootstrap

Este repositorio actúa como un lanzador ("bootstrap") para desplegar y actualizar los repositorios privados de la infraestructura Komodo (`common-tools`, `komodo-core` y `komodo-periphery`). 

Está diseñado específicamente para entornos restrictivos o sistemas de archivos de solo lectura como **TrueNAS SCALE**. Al incluir el binario portable de GitHub CLI (`gh`), evita la necesidad de instalar software a nivel de sistema operativo.

### 🛠️ Uso Rápido (Modo Interactivo)

Navega mediante SSH al directorio de tu NAS donde quieres alojar los proyectos de Komodo y sigue estos pasos:

**1. Clona este repositorio base:**
```bash
git clone https://github.com/docker-workflows/bootstrap.git ./bootstrap
```

**2. Autentícate con GitHub:**
```bash
./deploy.sh setup
```
> **Nota:** El script te dará un código de 8 caracteres. Cópialo, abre la URL que aparece en la terminal en tu navegador web y autoriza el acceso. No necesitas meter contraseñas en la terminal.

**3. Despliega los proyectos:**
```bash
./deploy.sh all prod
```
*Este comando descargará o actualizará los repositorios en el orden estricto de dependencias (`common-tools` -> `core` -> `periphery`) y aplicará los archivos `.env` correspondientes.*

### 🤖 Uso Automatizado (Sin intervención)

Si necesitas ejecutar este script mediante una tarea Cron o un pipeline, puedes inyectar un Personal Access Token (PAT) de GitHub como variable de entorno. El script lo detectará y se saltará el login interactivo:

```bash
export GH_TOKEN=ghp_tu_token_secreto_aqui
./deploy.sh all prod
```

### 🔒 Nota sobre Seguridad
Para garantizar que no queden credenciales huérfanas en el sistema, la configuración de Git y la sesión de `gh` se aíslan en un directorio temporal (`/tmp/komodo-gh-config`). Al terminar la ejecución de `./deploy.sh all prod`, el script **destruye automáticamente** estas credenciales. Si necesitas limpiar la sesión manualmente, puedes ejecutar `./deploy.sh clean-auth`.