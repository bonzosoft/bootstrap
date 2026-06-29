Ese combo de herramientas (`pwsh` + `git` + `gh` + `sops` + `age`) es el auténtico "Dream Team" del GitOps moderno y soberano. Tienes todo lo necesario dentro del contenedor para clonar, autenticarte, desencriptar y desplegar sin depender de una sola pieza de infraestructura externa.

La inclusión de **`gh` (GitHub CLI)** es un superpoder para tu contenedor volátil, porque te resuelve el problema de dónde guardar y cómo recuperar la clave privada de `age` de forma segura, tanto si ejecutas el contenedor en tu máquina local como en un servidor remoto.

Así es como se orquesta el flujo completo dentro de tu script de PowerShell utilizando tus herramientas preinstaladas:

### El Flujo de Trabajo en tu Script de PowerShell (`deploy.ps1`)

Este script aprovecha `gh` para obtener el "Secreto Cero" (la clave privada de `age`) guardado de forma segura en los secretos de tu repositorio de GitHub, configurando SOPS al vuelo para aplicar la configuración del tenant.

```powershell
param (
    [Parameter(Mandatory=$true)]
    [string]$TenantName,

    [Parameter(Mandatory=$true)]
    [string]$RepoUrl # Ej: "owner/my-infra-repo"
)

Write-Host "🚀 Iniciando despliegue para el tenant: $TenantName" -ForegroundColor Cyan

# 1. Autenticación y descarga del Secreto Cero usando 'gh'
# Asumimos que el contenedor ya está autenticado con GH_TOKEN o mediante 'gh auth login'
Write-Host "🔑 Recuperando clave de encriptación desde GitHub Secrets..."
try {
    # Guardamos el nombre del secreto según el tenant (ej: TENANT_A_AGE_KEY)
    $SecretName = "$($TenantName.ToUpper().Replace("-","_"))_AGE_KEY"
    
    # gh nos permite traer el valor del secreto directamente a una variable de memoria
    $AgePrivateKey = gh secret view $SecretName --repo $RepoUrl --raw
    
    if ([string]::IsNullOrEmpty($AgePrivateKey)) { throw "La clave recuperada está vacía." }
} catch {
    Write-Error "❌ Error al recuperar el secreto $SecretName desde GitHub: $_"
    Exit 1
}

# 2. Inyectar la clave en el entorno para SOPS
# Al ser un contenedor volátil, esto solo vive en la RAM de esta ejecución
$Env:SOPS_AGE_KEY = $AgePrivateKey

# 3. Definir rutas de los archivos del Tenant
$TenantFolder = "./tenants/$TenantName"
$SecretFile   = "$TenantFolder/smtp-secret.enc.yaml"
$ConfigFile   = "$TenantFolder/config.yaml"

# 4. Desencriptar el secreto SMTP y combinarlo con la configuración pública
if (Test-Path $SecretFile) {
    Write-Host "🔓 Desencriptando credenciales SMTP con SOPS..."
    $DecryptedSmtp = sops --decrypt $SecretFile | ConvertFrom-Yaml
    
    # Leer la configuración pública (no encriptada)
    $PublicConfig = Get-Content $ConfigFile | ConvertFrom-Yaml
    
    # 5. Aquí tienes toda tu configuración unificada en memoria (Cero archivos temporales en disco)
    $FinalConfig = @{
        Tenant = $TenantName
        Port   = $PublicConfig.smtp_port
        User   = $PublicConfig.smtp_user
        Pass   = $DecryptedSmtp.smtp.password # <-- El dato protegido
    }
    
    Write-Host "✅ Configuración cargada con éxito para $TenantName" -ForegroundColor Green
} else {
    Write-Error "❌ No se encontró el archivo de secretos en $SecretFile"
    Exit 1
}

# 6. Ejecutar el despliegue final
# Aquí invocas tus comandos habituales usando la variable $FinalConfig
# Ej: ./tu-script-de-infra.ps1 -Config $FinalConfig

```

---

### Cómo ejecutar tu contenedor

Al lanzar el contenedor, solo necesitas asegurarte de pasarle la credencial de GitHub (`GH_TOKEN`). `gh` la detectará automáticamente para poder hablar con la API de GitHub y descargar la clave de `age`.

**Ejemplo de ejecución en local o servidor:**

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -e GH_TOKEN="ghp_TuTokenDeGitHubPersonalODeBot" \
  tu-imagen-pwsh-git-gh-sops:latest \
  pwsh -File /workspace/deploy.ps1 -TenantName "tenant-a" -RepoUrl "mi-organizacion/mi-repo-infra"

```

### Por qué esta arquitectura es ultra-robusta para tu caso:

1. **Cumple "Cero Dependencias":** Si GitHub desaparece, tus archivos siguen estando encriptados en tu disco local. Solo tendrías que pasarle la clave privada de `age` de forma manual al script eliminando el paso de `gh secret view`. Tu capacidad de reproducir la infra no muere.
2. **El contenedor es 100% agnóstico:** No guarda estado, no guarda claves en el `Dockerfile`. Si alguien roba la imagen del contenedor de tu Docker Registry, no se lleva absolutamente nada, porque está vacío.
3. **Mínimo privilegio:** El token de GitHub (`GH_TOKEN`) que le pasas al contenedor solo necesita permisos de lectura sobre el repositorio y sus secretos.

Con este flujo cerrado y tus herramientas integradas, ¿tienes resuelto cómo vas a manejar la rotación de esa clave de SMTP cuando expire, o quieres que veamos cómo estructurar esa automatización de cambio de clave usando `sops` y `pwsh`?