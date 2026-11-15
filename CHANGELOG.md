# Cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones con [SemVer](https://semver.org/lang/es/).

## 1.1.0 - 2026-11-15

### Agregado
- Bloqueo de anuncios, rastreadores y contenido patrocinado, activado de fábrica:
  - Oculta elementos de anuncio, patrocinio y avisos de cookies por clase, id, `data-ad*` y `aria-label`.
  - Quita enlaces a redes de anuncios y de rastreo y muestra **Página bloqueada** al abrir una, con opción *Abrir de todos modos*.
  - Limpia parámetros de rastreo (`utm_*`, `fbclid`, `gclid`, `msclkid` y otros) y desenvuelve redirectores de Google, Facebook, Instagram y YouTube.
  - Quita etiquetas de texto como "Publicidad" o "Contenido patrocinado".
  - Envía las cabeceras `DNT: 1` y `Sec-GPC: 1`.
- Lista de filtros integrada `app/filters/filtros.txt` con sintaxis básica de Adblock Plus (`||dominio^`, `##.clase`, `###id`, `@@`).
- Descarga opcional de la lista de Peter Lowe desde el menú.
- Contador de bloqueos en el encabezado y submenú **Bloqueo de anuncios y rastreadores**: encender o apagar, pausar por sitio, actualizar la lista.
- Si el filtro deja una página casi vacía, se vuelve a mostrar sin ocultar elementos.
- Pruebas automáticas: 32 casos; `npm test` falla si alguno no pasa.
- Documentación: `docs/BLOQUEO.md`, imágenes del submenú y comparación antes y después.

### Cambiado
- La versión de la app pasa a 1.1 (build 2). El ZIP incluye la carpeta `filters/`.

### Pruebas
- Validado con BrighterScript y con el intérprete `brs`. Pendiente: confirmar en televisores reales, en especial el submenú y la descarga de la lista.

## 1.0.0 - 2026-11-15

Primera versión.

### Agregado
- Navegador en modo lectura: descarga páginas HTTP/HTTPS y muestra títulos, texto y enlaces.
- Búsqueda en la web con DuckDuckGo (versión HTML) desde el mismo cuadro de dirección.
- Pantalla de inicio con favoritos de ejemplo y resumen de controles.
- Favoritos guardados en el registro del Roku.
- Historial de 30 páginas con regreso a la posición anterior.
- Saltos entre enlaces (Izquierda/Derecha) y por pantalla (Retroceder/Avanzar).
- Menú con inicio, recargar, favoritos y opción para ocultar enlaces dentro de párrafos.
- Avisos para páginas vacías, errores de red, errores HTTP y archivos no compatibles.

### Pruebas
- El código pasa la validación de BrighterScript sin errores.
- El analizador HTML se probó con el intérprete `brs` (casos difíciles y una página de 4,000 párrafos).
- Pendiente: confirmar el funcionamiento en televisores reales.
