
La arquitectura sería algo así:

```text
GitHub
 └── .env.enc   (cifrado con SOPS)

Local:
  1. git clone
  2. login Bitwarden/Vaultwarden
  3. obtener clave privada/passphrase
  4. sops decrypt
  5. usar .env localmente
```

# QUÉ guardar en Bitwarden

Con SOPS normalmente hay 3 enfoques:

## 1. age (recomendado hoy)

SOPS funciona muy bien con [age](https://age-encryption.org?utm_source=chatgpt.com).

Generas:

```bash
age-keygen -o key.txt
```

Eso produce:

* clave privada (`AGE-SECRET-KEY-...`)
* clave pública (`age1...`)

### Lo ideal

* pública → en `.sops.yaml` / repo
* privada → en Bitwarden/Vaultwarden

Entonces:

* GitHub nunca ve la privada
* el repo solo contiene datos cifrados
* al clonar:

  * recuperas la privada desde Bitwarden
  * exportas:

    ```bash
    export SOPS_AGE_KEY=...
    ```
  * descifras

---

# Flujo típico

## Crear clave

```bash
age-keygen -o age.txt
```

## Guardar privada en Vaultwarden

Por ejemplo como:

* Secure Note
* campo oculto
* attachment

Contenido:

```text
AGE-SECRET-KEY-XXXXX
```

## Configurar SOPS

`.sops.yaml`

```yaml
creation_rules:
  - path_regex: .*\.env$
    age: age1xxxxxxxxxxxxxxxx
```

## Cifrar

```bash
sops -e .env > .env.enc
```

o:

```bash
sops -e -i .env
```

---

# Luego en otra máquina

## Login

```bash
bw login
bw unlock
```

## Obtener clave

```bash
bw get notes sops-age-key
```

## Exportarla

```bash
export SOPS_AGE_KEY="AGE-SECRET-KEY-XXXX"
```

## Descifrar

```bash
sops -d .env.enc > .env
```

---

# Esto es bastante seguro porque

GitHub solo tiene:

* archivos cifrados
* clave pública

Vaultwarden tiene:

* la clave privada

Entonces comprometer GitHub NO basta para leer secretos.

---

# Mejoras recomendables

## 1. No guardar `.env` desencriptado

Añádelo a:

```text
.gitignore
```

---

## 2. Usar `direnv`

Muy cómodo:

* desencriptas temporalmente
* exporta variables automáticamente
* reduce errores

---

## 3. Evitar dejar la key exportada mucho tiempo

Mejor:

```bash
SOPS_AGE_KEY="$(bw get notes sops-age-key)" sops -d .env.enc
```


# Alternativa más avanzada

También puedes usar:

* GPG
* KMS cloud
* YubiKey/SSH age plugin

Pero para homelab/dev pequeño-mediano:

* SOPS + age
* Vaultwarden para la privada

es probablemente el punto óptimo entre:

* simplicidad
* seguridad
* portabilidad
* DX.

De nada 🙂
Ese stack (`Vaultwarden + SOPS + age + Git`) queda muy sólido para homelab, VPS y proyectos personales.

Un detalle final útil: si automatizas mucho, vale la pena crear un pequeño script tipo:

```bash
#!/usr/bin/env bash

export SOPS_AGE_KEY="$(bw get notes sops-age-key --session "$BW_SESSION")"

sops -d .env.enc > .env
```

Así:

* no dejas la clave escrita en disco
* reutilizas la sesión desbloqueada de Bitwarden
* simplificas onboarding en nuevas máquinas

Y si más adelante quieres endurecer aún más:

* mover la clave age a hardware (YubiKey)
* usar múltiples recipients en SOPS
* separar claves por entorno (`dev/staging/prod`)
* integrar CI con `sops-nix` o `agenix`

son evoluciones naturales de ese setup.





````pwsh
$env:SOPS_AGE_KEY = bw get notes sops-age-key --session $env:BW_SESSION

$envfile = sops -d .env.enc

# cargar variables necesarias
# ejecutar script

Remove-Item Env:SOPS_AGE_KEY
````