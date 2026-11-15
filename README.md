<p align="center">
  <img src="docs/images/banner.png" alt="RokuBrowser: navegador web en modo lectura para televisores Roku" width="100%">
</p>

<p align="center">
  <a href="https://github.com/web-gdl/RokuBrowser/raw/main/download/NavegadorWebRoku.zip"><b>⬇️ Descargar NavegadorWebRoku.zip</b></a>
  &nbsp;·&nbsp;
  <a href="docs/INSTALACION.md">Instalación</a>
  &nbsp;·&nbsp;
  <a href="docs/USO.md">Manual de uso</a>
  &nbsp;·&nbsp;
  <a href="docs/ARQUITECTURA.md">Arquitectura</a>
  &nbsp;·&nbsp;
  <a href="docs/DESARROLLO.md">Desarrollo</a>
</p>

# RokuBrowser

**RokuBrowser** es un navegador web para televisores y reproductores **Roku**, escrito en BrightScript y SceneGraph. Se instala por *sideload* desde el modo desarrollador, sin pasar por la tienda de canales.

Roku no incluye un motor HTML ni JavaScript, así que no es posible un navegador como Chrome. RokuBrowser trabaja en **modo lectura**: descarga la página, extrae los títulos, el texto y los enlaces, y los muestra en una lista que se recorre con el control remoto.

<p align="center">
  <img src="docs/images/pantalla-pagina.png" alt="Simulación de una página abierta en RokuBrowser" width="85%">
</p>

> Las pantallas de esta documentación son **simulaciones** dibujadas con las mismas medidas, colores y textos que usa la app (ver [`tools/make_images.py`](tools/make_images.py)). No son capturas de un televisor.

## Características

- 🌐 Abre cualquier dirección `http://` o `https://`.
- 🔎 Busca en la web desde el mismo cuadro (DuckDuckGo en su versión HTML).
- 🔗 Los enlaces se ven en azul; **Izquierda/Derecha** salta directo al anterior o al siguiente.
- ⭐ Favoritos que se guardan en el propio Roku y siguen ahí después de apagarlo.
- ↩️ Historial: **Back** regresa a la página anterior (hasta 30 páginas).
- 📄 Avance por pantallas con **Retroceder / Avanzar**.
- 🧹 Quita scripts, estilos y comentarios; convierte entidades HTML (`&aacute;` → á) y URLs relativas.
- 🇲🇽 Interfaz en español.

## Qué funciona y qué no

| Funciona bien | No funciona |
|---|---|
| Wikipedia (versión móvil) | Imágenes y video |
| Sitios de noticias y blogs | Sitios que dependen de JavaScript (YouTube, Facebook, apps web) |
| Versiones "lite" o de solo texto | Formularios e inicios de sesión |
| Documentación y páginas de texto | Páginas con codificación distinta de UTF-8 (algunos acentos pueden verse mal) |

Si una página no tiene texto legible, el navegador lo avisa y ofrece volver al inicio.

## Instalación rápida

<p align="center">
  <img src="docs/images/instalacion.png" alt="Instalación en 3 pasos" width="100%">
</p>

1. **Activa el modo desarrollador** en tu Roku: en el control pulsa `Inicio ×3, Arriba ×2, Derecha, Izquierda, Derecha, Izquierda, Derecha`. Anota la dirección IP que aparece y crea una contraseña.
2. **Descarga** [`NavegadorWebRoku.zip`](https://github.com/web-gdl/RokuBrowser/raw/main/download/NavegadorWebRoku.zip). No lo descomprimas.
3. En una computadora conectada a la misma red, abre `http://IP-DE-TU-ROKU`, entra con el usuario `rokudev` y tu contraseña, pulsa **Upload**, elige el ZIP y luego **Install with zip**.

Guía completa, con solución de problemas: [docs/INSTALACION.md](docs/INSTALACION.md).

## Controles

<p align="center">
  <img src="docs/images/controles.png" alt="Controles del navegador en el control remoto" width="70%">
</p>

| Botón | Acción |
|---|---|
| Arriba / Abajo | Moverse por la página, línea por línea |
| OK | Abrir el enlace seleccionado |
| Izquierda / Derecha | Saltar al enlace anterior o siguiente |
| Retroceder / Avanzar | Subir o bajar una pantalla |
| Play | Escribir una dirección o una búsqueda |
| Asterisco (`*`) | Menú: inicio, recargar, favoritos, mostrar u ocultar enlaces de párrafos |
| Repetir (`↺`) | Recargar la página |
| Back | Página anterior; en la pantalla de inicio sale de la app |

Más detalles en el [manual de uso](docs/USO.md).

## Pantallas

| Inicio | Teclado | Menú |
|---|---|---|
| ![Pantalla de inicio](docs/images/pantalla-inicio.png) | ![Teclado](docs/images/pantalla-teclado.png) | ![Menú](docs/images/pantalla-menu.png) |

## Estructura del proyecto

```text
RokuBrowser/
├── app/                      Código del canal (lo que va dentro del ZIP)
│   ├── manifest
│   ├── source/main.brs
│   ├── components/
│   │   ├── MainScene.xml/.brs    Interfaz y control remoto
│   │   ├── BrowserTask.xml/.brs  Red, inicio y favoritos (hilo aparte)
│   │   ├── HtmlParser.brs        HTML → líneas de texto y enlaces
│   │   └── LineItem.xml/.brs     Una fila de la lista
│   └── images/               Icono, splash y foco
├── download/                 NavegadorWebRoku.zip listo para instalar
├── docs/                     Documentación e imágenes
├── tools/
│   ├── build.sh              Genera el ZIP
│   ├── make_images.py        Genera iconos e imágenes de la documentación
│   └── test/                 Prueba del analizador HTML
├── .github/workflows/        Publica la release al subir una etiqueta v*
├── bsconfig.json             Configuración de BrighterScript (validación)
└── package.json
```

## Compilar desde el código

```bash
npm install          # instala BrighterScript y el intérprete brs
npm run lint         # valida todo el código BrightScript
npm test             # prueba el analizador HTML con una página de ejemplo
npm run build        # crea download/NavegadorWebRoku.zip
```

Guía para desarrolladores: [docs/DESARROLLO.md](docs/DESARROLLO.md).

## Compatibilidad

Pensado para la interfaz HD (1280×720), que Roku escala a cualquier televisor. Probado en el desarrollo con el compilador BrighterScript y con el intérprete `brs`; las pruebas en dispositivos reales se van anotando en el [CHANGELOG](CHANGELOG.md). Si lo pruebas en tu Roku, abre un *issue* con el modelo y el resultado.

## Licencia

[MIT](LICENSE). Roku es una marca registrada de Roku, Inc.; este proyecto no está afiliado ni respaldado por Roku.
