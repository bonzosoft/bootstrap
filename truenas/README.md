Sí, la sintaxis que está usando la comunidad de TrueNAS SCALE es básicamente un **Data URI** embebido en el campo `icon:` del `metadata.yaml`. ([TrueNAS Community Forums][1])

Queda así:

```yaml
metadata:
  icon: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...'
```

o si es SVG:

```yaml
metadata:
  icon: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDov...'
```

La clave es:

* incluir el prefijo:

  * `data:image/png;base64,`
  * `data:image/svg+xml;base64,`
  * `data:image/webp;base64,`
* todo en **una sola línea**
* entre comillas simples `'...'`
* sin saltos de línea en el Base64 (`base64 -w 0`)

Ejemplo real desde shell:

```bash
ICON=$(base64 -w 0 logo.png)

echo "data:image/png;base64,$ICON"
```

o directamente:

```bash
echo "metadata:
  icon: 'data:image/png;base64,$(base64 -w 0 logo.png)'"
```

Normalmente el fichero está en:

```bash
/mnt/.ix-apps/app_configs/TU_APP/metadata.yaml
```

aunque en versiones recientes algunos usuarios indican que también existe:

```bash
/mnt/.ix-apps/metadata.yaml
```

dependiendo de la versión de SCALE. ([TrueNAS Community Forums][2])

Ejemplo completo:

```yaml
metadata:
  name: jellyfin
  icon: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...'
```

Luego:

1. Guardas el YAML
2. Editas la app y haces Save
3. Refresco duro del navegador:

   * `CTRL + SHIFT + R`

Y aparece el icono custom. ([TrueNAS Community Forums][1])

[1]: https://forums.truenas.com/t/how-to-change-icon-of-custom-app/24789/25?page=2&utm_source=chatgpt.com "How to change icon of custom app? - #25 by adelzu - Apps and Virtualization - TrueNAS Community Forums"
[2]: https://forums.truenas.com/t/how-to-change-icon-of-custom-app/24789/30?utm_source=chatgpt.com "How to change icon of custom app? - #30 by Gamix - Apps and Virtualization - TrueNAS Community Forums"
