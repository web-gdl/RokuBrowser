# Cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones con [SemVer](https://semver.org/lang/es/).

## [1.0.0] - 2026-11-15

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

[1.0.0]: https://github.com/web-gdl/RokuBrowser/tree/v1.0.0
