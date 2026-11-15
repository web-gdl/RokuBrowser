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
| `npm test` | Ejecuta `tools/test/test.brs` con el intérprete `brs`: analiza `sample.html` e imprime las líneas |
| `npm run build` | Genera `dist/NavegadorWebRoku.zip` con el contenido de `app/` |
| `npm run images` | Regenera iconos, splash e imágenes de la documentación |

En Windows sin `bash`, empaqueta con PowerShell:

```powershell
Compress-Archive -Path app\* -DestinationPath dist\NavegadorWebRoku.zip -Force
```

## Instalar mientras desarrollas

1. Ejecuta `npm run build`.
2. Sube `dist/NavegadorWebRoku.zip` en `http://IP-DE-TU-ROKU` → **Upload** → **Install with zip**.
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

## Probar el analizador

`tools/test/sample.html` contiene casos difíciles: scripts con `<` y `>`, comentarios, entidades, enlaces relativos, tarjetas, enlaces `javascript:` y redirecciones de DuckDuckGo. Al cambiar `HtmlParser.brs`, ejecuta `npm test` y revisa que la salida siga teniendo sentido.

Para probar una página real, guárdala como `tools/test/sample.html` y vuelve a ejecutar la prueba.

## Publicar una versión

1. Sube `build_version` (y `minor_version` o `major_version` si corresponde) en `app/manifest`.
2. Actualiza `CHANGELOG.md`.
3. `npm run build`.
4. Crea una *release* en GitHub con la etiqueta `vX.Y.Z` y adjunta `dist/NavegadorWebRoku.zip` con ese nombre exacto. Así el enlace `releases/latest/download/NavegadorWebRoku.zip` siempre apunta a la última versión.

## Ideas para siguientes versiones

- Mostrar imágenes con nodos `Poster`.
- Reproducir enlaces `.mp4` y `.m3u8` con el nodo `Video`.
- Formularios de búsqueda simples (método GET).
- Detectar la codificación (`charset`) de páginas que no usan UTF-8.
- Un servidor intermediario opcional que renderice sitios con JavaScript y entregue HTML simple.
