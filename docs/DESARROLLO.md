# Guía para desarrolladores

[← Volver al inicio](../README.md)

## Herramientas

- [Node.js](https://nodejs.org/) 18 o superior (para validar, probar y empaquetar).
- [Visual Studio Code](https://code.visualstudio.com/) con la extensión **BrightScript Language** de RokuCommunity: resaltado, errores en vivo y depuración en el Roku con F5.
- Python 3 con Pillow, solo si vas a regenerar las imágenes.
- `zip` (Linux/macOS) o PowerShell (Windows) para el empaquetado.

```bash
git clone https://github.com/web-gdl/RokuBrowser.git
cd RokuBrowser
npm install
```

## Comandos

| Comando | Qué hace |
|---|---|
| `npm run lint` | Valida todo el BrightScript y los XML con BrighterScript |
| `npm test` | Ejecuta las 32 pruebas de `tools/test/test.brs` con el intérprete `brs` (analizador y bloqueo) y falla si alguna no pasa |
| `npm run build` | Genera `download/NavegadorWebRoku.zip` con el contenido de `app/` (este archivo se sube al repositorio) |
| `npm run images` | Regenera iconos, splash e imágenes de la documentación |

En Windows sin `bash`, empaqueta con PowerShell:

```powershell
Compress-Archive -Path app\* -DestinationPath download\NavegadorWebRoku.zip -Force
```

## Instalar mientras desarrollas

1. Ejecuta `npm run build`.
2. Sube `download/NavegadorWebRoku.zip` en `http://IP-DE-TU-ROKU` → **Upload** → **Install with zip**.
3. Abre la consola: `telnet IP-DE-TU-ROKU 8085`.

Con la extensión de VS Code puedes hacerlo todo con **F5** creando `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "brightscript",
      "request": "launch",
      "name": "Roku",
      "host": "192.168.1.27",
      "password": "TU-CONTRASEÑA",
      "rootDir": "${workspaceFolder}/app"
    }
  ]
}
```

No subas ese archivo con tu contraseña: `.vscode/` está en `.gitignore`.

## Reglas del código

- **BrightScript sin dependencias.** El canal no usa bibliotecas externas.
- **Nada de red en el hilo de render.** `roUrlTransfer` y `roRegistrySection` solo dentro de `BrowserTask`.
- **Evita nombres reservados** como identificadores (`run`, `on`, `input`…): BrighterScript los marca como error.
- **Textos de la interfaz en español**, con acentos (los archivos están en UTF-8).
- Cada cambio debe pasar `npm run lint` y `npm test` sin errores.

## Pruebas

- `tools/test/sample.html`: casos difíciles del analizador (scripts con `<` y `>`, comentarios, entidades, enlaces relativos, tarjetas, enlaces `javascript:`, redirecciones de DuckDuckGo).
- `tools/test/anuncios.html`: una noticia con anuncios anidados, `adsbygoogle`, Taboola, aviso de cookies, `<li>` patrocinado sin cerrar, enlaces con `utm_*` y `fbclid`, redirectores de Google y Facebook, clics de anuncios de Bing y DuckDuckGo, y clases legítimas que **no** deben ocultarse (`header`, `badge`, `download`, `shadow`).

`npm test` imprime las líneas resultantes y termina con `PRUEBAS: N correctas, M fallidas`. Cada caso nuevo se agrega con `check("descripción", condición)` en `test.brs`.

Para revisar una página real, guarda su HTML en `tools/test/` y analízala desde `test.brs`.

## Editar la lista de filtros

Las reglas están en `app/filters/filtros.txt` (sintaxis en [BLOQUEO.md](BLOQUEO.md#sintaxis-de-filtrostxt)). Después de editarla, ejecuta `npm test` para comprobar que no se oculta contenido legítimo y `npm run build` para generar el ZIP.

## Publicar una versión

1. Sube `build_version` (y `minor_version` o `major_version` si corresponde) en `app/manifest`.
2. Actualiza `CHANGELOG.md`.
3. `npm run build` y confirma el nuevo `download/NavegadorWebRoku.zip` junto con el código. El enlace de descarga del README apunta a ese archivo en `main`, así que siempre entrega la última versión.
4. Opcional: crea la etiqueta y súbela para que GitHub Actions publique la *release* con el ZIP adjunto ([`.github/workflows/release.yml`](../.github/workflows/release.yml)):

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

   Requiere que Actions tenga permiso de escritura (Settings → Actions → General → *Workflow permissions* → *Read and write*).

## Ideas para siguientes versiones

- Mostrar imágenes con nodos `Poster` (aplicando el bloqueo también a las imágenes de anuncios).
- Reproducir enlaces `.mp4` y `.m3u8` con el nodo `Video`.
- Formularios de búsqueda simples (método GET).
- Detectar la codificación (`charset`) de páginas que no usan UTF-8.
- Un servidor intermediario opcional que renderice sitios con JavaScript y entregue HTML simple.
