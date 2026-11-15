# Arquitectura

[← Volver al inicio](../README.md)

![Arquitectura de la app](images/arquitectura.png)

RokuBrowser es un canal SceneGraph. La interfaz vive en el hilo de render (`MainScene`) y todo el trabajo lento (red, análisis del HTML, registro) ocurre en un `Task` aparte (`BrowserTask`), para que la pantalla no se congele mientras carga.

## Componentes

### `source/main.brs`
Punto de entrada. Crea la pantalla `roSGScreen`, la escena `MainScene` y espera a que se cierre.

### `components/MainScene.xml` / `.brs`
La interfaz y el control remoto.

- **Diseño** (1280×720): encabezado con título y dirección, una `MarkupList` de 16 filas de 34 px y un pie con los controles.
- **Navegación**: `navigate(target, push)` crea un `BrowserTask` con `action = "load"`. Cuando el task termina, la página se convierte en la actual y, si `push` es verdadero, la anterior pasa al historial.
- **Historial**: hasta 30 entradas `{ url, title, content, links, index }`. Solo las 6 más recientes conservan su `ContentNode`; las demás guardan la dirección y la posición, y se descargan otra vez al volver.
- **Diálogos**: `StandardKeyboardDialog` para la dirección y `StandardMessageDialog` para el menú. Mientras hay un diálogo abierto, `onKeyEvent` no procesa teclas.
- **Saltos**: `links` es la lista de índices de filas que son enlaces; Izquierda/Derecha buscan el anterior o el siguiente respecto a la fila enfocada.

### `components/BrowserTask.xml` / `.brs`
Hilo de trabajo. Campos:

| Campo | Dirección | Uso |
|---|---|---|
| `action` | entrada | `"load"` o `"bookmark"` |
| `input` | entrada | Dirección, búsqueda o página interna (`app:home`) |
| `pageTitle` | entrada | Título al guardar un favorito |
| `inlineLinks` | entrada | Mostrar enlaces dentro de párrafos |
| `content` | salida | `ContentNode` con una fila por hijo |
| `result` | salida | `{ url, title, links }` o `{ message }`. Se asigna al final: la escena lo observa |

Pasos de `loadPage`:

1. `toUrl()` decide si el texto es una dirección o una búsqueda.
2. Rechaza extensiones de imagen, video y archivos antes de descargar.
3. `httpGet()` descarga con `roUrlTransfer` (certificados de Roku, cookies, gzip, 25 s de espera).
4. Según el `Content-Type`, usa `parseHtml()` o `plainPage()`.
5. `publish()` convierte las líneas en `ContentNode` y entrega el resultado.

Los favoritos se guardan como JSON en el registro del Roku (`roRegistrySection "navegador"`, clave `bookmarks`).

### `components/HtmlParser.brs`
Convierte HTML en líneas `{ t: texto, k: tipo, u: url }`, donde el tipo es `t` (texto), `h` (título), `l` (enlace) o `m` (nota).

No es un analizador DOM completo; recorre el HTML una sola vez partiéndolo en `<`:

- Ignora el contenido de `script`, `style`, `svg`, `noscript`, `template`, `iframe`, etc., y los comentarios.
- Las etiquetas de bloque (`p`, `div`, `li`, `h1`…`h6`, `tr`…) cierran el párrafo actual.
- Cada párrafo produce primero su texto (ajustado a 80 caracteres por línea) y debajo sus enlaces. Si el párrafo es casi solo enlaces (un menú), no se repite el texto.
- Un enlace que envuelve varios bloques (una "tarjeta") se mantiene como un solo enlace.
- Resuelve URLs relativas (`/ruta`, `../ruta`, `?consulta`, `//host`), aplica `<base href>`, descarta `javascript:`, `mailto:` y anclas `#`, y extrae el destino real de los enlaces de DuckDuckGo (`uddg=`).
- Decodifica entidades con nombre comunes en español y las numéricas (`&#233;`, `&#xE9;`).

### `components/LineItem.xml` / `.brs`
El componente de cada fila de la `MarkupList`. Lee el tipo desde `shortDescriptionLine1` y elige fuente y color.

## Decisiones de diseño

- **Modo lectura en vez de motor web.** Roku no ofrece un componente de navegador. Renderizar HTML/CSS completo en BrightScript sería enorme y lento; el texto con enlaces cubre bien la lectura de noticias, Wikipedia y documentación.
- **Una lista de filas.** La `MarkupList` solo crea las filas visibles, así que una página de 1,500 líneas no satura la memoria, y el enfoque del control remoto funciona sin código extra.
- **El campo `result` se asigna al final.** Así la escena nunca recibe un `result` sin su `content`.
- **DuckDuckGo HTML** para las búsquedas porque funciona sin JavaScript y sin clave de API.
