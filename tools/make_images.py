#!/usr/bin/env python3
"""Genera las imagenes de la documentacion (docs/images) y los iconos de la app.

Las pantallas son simulaciones dibujadas con las mismas medidas, colores y
textos que usa la app (MainScene.xml / LineItem.brs). No son capturas reales.

Uso:  python3 tools/make_images.py
Requiere Pillow y las fuentes DejaVu.
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "images")
os.makedirs(OUT, exist_ok=True)

FONT_DIR = "/usr/share/fonts/truetype/dejavu/"
R = FONT_DIR + "DejaVuSans.ttf"
B = FONT_DIR + "DejaVuSans-Bold.ttf"
M = FONT_DIR + "DejaVuSansMono.ttf"


def font(path, size):
    return ImageFont.truetype(path, size)


# Colores de la app
BG = "#101820"
BAR = "#1B2838"
WHITE = "#FFFFFF"
GREY = "#8FA3B8"
TEXT = "#E8EAED"
LINK = "#7FB8FF"
HEAD = "#FFD166"
NOTE = "#9AA5B1"
FOCUS = "#2D6CDF"
PURPLE = "#662D91"
GREEN = "#7EE787"


def globe(d, cx, cy, r, w, col):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=w)
    d.ellipse([cx - r * 0.45, cy - r, cx + r * 0.45, cy + r], outline=col, width=w)
    d.line([cx - r, cy, cx + r, cy], fill=col, width=w)
    d.line([cx, cy - r, cx, cy + r], fill=col, width=w)
    for k in (-0.5, 0.5):
        y = cy + k * r
        h = (r * r - (k * r) ** 2) ** 0.5
        d.line([cx - h, y, cx + h, y], fill=col, width=w)


def center_text(d, y, text, f, fill, width):
    d.text(((width - d.textlength(text, font=f)) / 2, y), text, font=f, fill=fill)


def rounded(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


# ------------------------------------------------------------------ pantallas

HINTS = ("OK: abrir enlace   |   Izq/Der: saltar entre enlaces   |   Rew/FF: página   |"
         "   Play: dirección   |   * : menú   |   Back: atrás")


def screen(title, url, rows, focus_index, status="", shield="", shield_color=None):
    """Dibuja la escena principal a 1280x720 igual que MainScene.xml."""
    im = Image.new("RGB", (1280, 720), BG)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 1280, 98], fill=BAR)
    d.text((64, 28), title, font=font(B, 24), fill=WHITE)
    d.text((64, 62), url, font=font(R, 18), fill=GREY)
    if shield:
        f = font(R, 18)
        d.text((1216 - d.textlength(shield, font=f), 34), shield, font=f, fill=shield_color or GREEN)
    if status:
        f = font(R, 18)
        d.text((1216 - d.textlength(status, font=f), 62), status, font=f, fill=HEAD)

    fn, fb = font(R, 21), font(B, 21)
    for i, (kind, text) in enumerate(rows[:16]):
        y = 104 + i * 34
        focused = i == focus_index
        if focused:
            d.rectangle([50, y, 1230, y + 33], fill=FOCUS)
        color = WHITE if focused else {"l": LINK, "h": HEAD, "m": NOTE}.get(kind, TEXT)
        d.text((62, y + 5), text, font=fb if kind == "h" else fn, fill=color)

    d.rectangle([0, 652, 1280, 720], fill=BAR)
    d.text((64, 661), HINTS, font=font(R, 16), fill=GREY)
    return im


HOME_ROWS = [
    ("h", "Navegador Web para Roku"),
    ("l", "» Escribir una dirección o buscar en la web"),
    ("h", "Favoritos"),
    ("l", "» Buscar en DuckDuckGo"),
    ("l", "» Wikipedia en español"),
    ("l", "» BBC News Mundo"),
    ("l", "» CNN Lite (inglés)"),
    ("l", "» NPR Text (inglés)"),
    ("l", "» Hacker News (inglés)"),
    ("h", "Controles"),
    ("m", "Arriba / Abajo: moverse por la página, línea por línea."),
    ("m", "OK: abrir el enlace seleccionado (los enlaces se ven en azul)."),
    ("m", "Izquierda / Derecha: saltar al enlace anterior o siguiente."),
    ("m", "Retroceder / Avanzar: subir o bajar una pantalla completa."),
    ("m", "Play: escribir una dirección o una búsqueda."),
    ("m", "Asterisco (*): menú con inicio, recargar, favoritos y bloqueo de anuncios."),
]

# Pagina de ejemplo (contenido ficticio, solo para ilustrar el formato)
PAGE_ROWS = [
    ("l", "» Inicio"),
    ("l", "» Artículos"),
    ("l", "» Contacto"),
    ("h", "Cómo funciona la televisión por internet"),
    ("t", "La televisión por internet envía el video en pequeños fragmentos que el"),
    ("t", "reproductor descarga uno tras otro. Así la imagen empieza a verse en pocos"),
    ("t", "segundos, aunque el archivo completo sea muy grande."),
    ("l", "» Qué es el streaming adaptativo"),
    ("h", "Ventajas"),
    ("t", "• La calidad se ajusta sola a la velocidad de la conexión."),
    ("t", "• No hace falta descargar el programa completo antes de verlo."),
    ("t", "• El mismo contenido sirve para teléfonos, computadoras y televisores."),
    ("h", "Para saber más"),
    ("l", "» Guía de formatos de video"),
    ("l", "» Preguntas frecuentes"),
    ("m", "Página de ejemplo creada para esta documentación."),
]


def overlay(im):
    """Oscurece la escena, como hace Roku al abrir un dialogo."""
    shade = Image.new("RGBA", im.size, (0, 0, 0, 150))
    out = im.convert("RGBA")
    out.alpha_composite(shade)
    return out


def dialog_frame(im, box, title):
    d = ImageDraw.Draw(im)
    rounded(d, box, 14, fill="#23272E", outline="#3A4250", width=2)
    d.text((box[0] + 36, box[1] + 26), title, font=font(B, 28), fill=WHITE)
    return d


def keyboard_screen():
    im = overlay(screen("Inicio", "", HOME_ROWS, 1))
    box = (190, 70, 1090, 650)
    d = dialog_frame(im, box, "Ir a una dirección o buscar")
    d.text((226, 140), "Escribe una dirección (ejemplo: es.wikipedia.org) o palabras",
           font=font(R, 19), fill="#C9D1D9")
    d.text((226, 164), "para buscar en la web.", font=font(R, 19), fill="#C9D1D9")
    rounded(d, (226, 200, 1054, 248), 6, fill="#0E1116", outline=FOCUS, width=2)
    d.text((242, 210), "es.wikipedia.org|", font=font(R, 22), fill=WHITE)
    keys = ["abcdefg", "hijklmn", "opqrstu", "vwxyz.-", "1234567"]
    kf = font(B, 22)
    for r, row in enumerate(keys):
        for c, ch in enumerate(row):
            x, y = 226 + c * 62, 266 + r * 52
            focused = (r, c) == (2, 4)
            rounded(d, (x, y, x + 54, y + 44), 6, fill=FOCUS if focused else "#323844")
            d.text((x + 27 - d.textlength(ch, font=kf) / 2, y + 9), ch, font=kf, fill=WHITE)
    side = ["Espacio", "Borrar", ".com", "https://", "www."]
    for i, s in enumerate(side):
        y = 266 + i * 52
        rounded(d, (680, y, 860, y + 44), 6, fill="#323844")
        d.text((770 - d.textlength(s, font=font(R, 19)) / 2, y + 11), s, font=font(R, 19), fill=WHITE)
    for i, s in enumerate(["Ir", "Cancelar"]):
        y = 548 + i * 48
        rounded(d, (226, y, 1054, y + 42), 6, fill="#3A4250")
        d.text((246, y + 9), s, font=font(R, 21), fill=WHITE)
    return im.convert("RGB")


def menu_screen():
    im = overlay(screen("Cómo funciona la televisión por internet",
                        "https://ejemplo.org/articulos/tv-por-internet", PAGE_ROWS, 7,
                        shield="Bloqueados: 7  ·  Rastreo: 3"))
    box = (300, 86, 980, 650)
    d = dialog_frame(im, box, "Menú")
    items = ["Ir a dirección o buscar", "Inicio", "Recargar página", "Guardar o quitar favorito",
             "Bloqueo de anuncios y rastreadores", "Ocultar enlaces dentro de párrafos", "Cerrar menú"]
    for i, s in enumerate(items):
        y = 160 + i * 66
        rounded(d, (336, y, 944, y + 52), 8, fill=FOCUS if i == 4 else "#3A4250")
        d.text((360, y + 13), s, font=font(R, 22), fill=WHITE)
    return im.convert("RGB")


def adblock_screen():
    im = overlay(screen("Cómo funciona la televisión por internet",
                        "https://ejemplo.org/articulos/tv-por-internet", PAGE_ROWS, 7,
                        shield="Bloqueados: 7  ·  Rastreo: 3"))
    box = (170, 60, 1110, 660)
    d = dialog_frame(im, box, "Bloqueo de anuncios y rastreadores")
    msg = [
        "Estado: activado.",
        "En esta página: 5 elementos de anuncio, patrocinio o cookies ocultos;",
        "1 enlace de anuncios o rastreo quitado; 1 etiqueta de publicidad",
        "quitada; 3 enlaces limpiados de rastreo.",
        "Reglas cargadas: 3,689.",
        "Lista de Peter Lowe: 3,544 dominios, actualizada el 15/11/2026.",
    ]
    f = font(R, 20)
    y = 134
    for i, line in enumerate(msg):
        if i in (1, 4, 5):
            y += 12
        d.text((206, y), line, font=f, fill="#C9D1D9")
        y += 28
    buttons = ["Desactivar bloqueo en todo el navegador", "Pausar bloqueo en ejemplo.org",
               "Actualizar lista de filtros", "Cerrar"]
    for i, b in enumerate(buttons):
        by = 380 + i * 64
        rounded(d, (206, by, 1074, by + 52), 8, fill=FOCUS if i == 1 else "#3A4250")
        d.text((230, by + 13), b, font=font(R, 22), fill=WHITE)
    return im.convert("RGB")


# Misma pagina sin bloqueo (con anuncios) y con bloqueo
ADS_ROWS = [
    ("t", "Usamos cookies para mejorar tu experiencia. Al continuar, aceptas."),
    ("l", "» Aceptar todo"),
    ("l", "» Inicio"),
    ("l", "» Artículos"),
    ("h", "Cómo funciona la televisión por internet"),
    ("t", "Publicidad"),
    ("l", "» ¡Compra ya! 70% de descuento en televisores"),
    ("t", "La televisión por internet envía el video en pequeños fragmentos que el"),
    ("t", "reproductor descarga uno tras otro."),
    ("l", "» Qué es el streaming adaptativo"),
    ("h", "Contenido patrocinado"),
    ("l", "» El truco que los bancos no quieren que conozcas"),
    ("l", "» Médicos sorprendidos por este remedio casero"),
    ("h", "Ventajas"),
    ("t", "• La calidad se ajusta sola a la velocidad de la conexión."),
    ("l", "» Guía de formatos de video"),
]
CLEAN_ROWS = [
    ("l", "» Inicio"),
    ("l", "» Artículos"),
    ("h", "Cómo funciona la televisión por internet"),
    ("t", "La televisión por internet envía el video en pequeños fragmentos que el"),
    ("t", "reproductor descarga uno tras otro."),
    ("l", "» Qué es el streaming adaptativo"),
    ("h", "Ventajas"),
    ("t", "• La calidad se ajusta sola a la velocidad de la conexión."),
    ("t", "• No hace falta descargar el programa completo antes de verlo."),
    ("t", "• El mismo contenido sirve para teléfonos, computadoras y televisores."),
    ("h", "Para saber más"),
    ("l", "» Guía de formatos de video"),
    ("l", "» Preguntas frecuentes"),
]


def before_after():
    url = "https://ejemplo.org/articulos/tv-por-internet"
    title = "Cómo funciona la televisión por internet"
    before = screen(title, url, ADS_ROWS, -1, shield="Bloqueo: apagado", shield_color=GREY)
    after = screen(title, url, CLEAN_ROWS, -1, shield="Bloqueados: 7  ·  Rastreo: 3")
    # marcar en rojo lo que el filtro quita
    d = ImageDraw.Draw(before)
    for i in (0, 1, 5, 6, 10, 11, 12):
        y = 104 + i * 34
        d.rectangle([52, y + 1, 1228, y + 32], outline="#F85149", width=3)
    W = 1500
    out = Image.new("RGB", (W, 520), "#FFFFFF")
    od = ImageDraw.Draw(out)
    for k, (im, label, col) in enumerate([(before, "Sin bloqueo", "#CF222E"), (after, "Con bloqueo", "#1A7F37")]):
        small = im.resize((704, 396), Image.LANCZOS)
        x = 30 + k * 736
        od.rounded_rectangle((x - 8, 62, x + 712, 466), radius=12, fill="#0B0B0D")
        out.paste(small, (x, 66))
        od.text((x, 16), label, font=font(B, 28), fill=col)
    center_text(od, 478, "Simulación: lo marcado en rojo (cookies, publicidad, enlaces de anuncios y patrocinados) desaparece",
                font(R, 19), "#57606A", W)
    out.save(os.path.join(OUT, "antes-despues.png"))


def framed(im, path, caption):
    """Pone la pantalla dentro de un marco de televisor con una etiqueta."""
    w, h = im.size
    pad, bottom = 28, 70
    tv = Image.new("RGB", (w + pad * 2, h + pad * 2 + bottom), "#FFFFFF")
    d = ImageDraw.Draw(tv)
    rounded(d, (0, 0, w + pad * 2, h + pad * 2), 18, fill="#0B0B0D")
    tv.paste(im, (pad, pad))
    d.rectangle([(w + pad * 2) / 2 - 90, h + pad * 2, (w + pad * 2) / 2 + 90, h + pad * 2 + 16], fill="#2A2A2E")
    center_text(d, h + pad * 2 + 30, caption, font(R, 22), "#57606A", w + pad * 2)
    tv.save(path)


# ------------------------------------------------------------- otras imagenes

def banner():
    im = Image.new("RGB", (1280, 400), BG)
    d = ImageDraw.Draw(im)
    for i in range(400):  # degradado suave
        c = int(16 + i * 0.05)
        d.line([0, i, 1280, i], fill=(c, c + 8, c + 16))
    globe(d, 230, 200, 120, 7, LINK)
    d.text((410, 110), "RokuBrowser", font=font(B, 76), fill=WHITE)
    d.text((414, 205), "Navegador web en modo lectura para televisores Roku",
           font=font(R, 28), fill=GREY)
    tags = ["BrightScript", "SceneGraph", "Bloqueo de anuncios", "Español"]
    x = 414
    for t in tags:
        f = font(B, 20)
        tw = d.textlength(t, font=f)
        rounded(d, (x, 268, x + tw + 32, 306), 19, fill="#1F3A5F")
        d.text((x + 16, 275), t, font=f, fill=LINK)
        x += tw + 48
    im.save(os.path.join(OUT, "banner.png"))


def remote():
    W, H = 1200, 900
    im = Image.new("RGB", (W, H), "#FFFFFF")
    d = ImageDraw.Draw(im)
    center_text(d, 30, "Controles del navegador", font(B, 38), "#1F2328", W)
    cx = 600
    rounded(d, (cx - 130, 110, cx + 130, 880), 90, fill="#2B2B33")
    # boton atras / inicio
    btn = {}

    def circle(name, x, y, r, label, col="#44444E"):
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)
        f = font(B, 22 if len(label) < 3 else 16)
        d.text((x - d.textlength(label, font=f) / 2, y - 12), label, font=f, fill=WHITE)
        btn[name] = (x, y, r)

    circle("back", cx - 60, 190, 34, "←")
    circle("home", cx + 60, 190, 34, "⌂")
    # cruceta
    d.ellipse([cx - 105, 260, cx + 105, 470], fill=PURPLE)
    for name, (x, y, lab) in {"up": (cx, 292, "▲"), "down": (cx, 438, "▼"),
                              "left": (cx - 72, 365, "◀"), "right": (cx + 72, 365, "▶")}.items():
        f = font(B, 26)
        d.text((x - d.textlength(lab, font=f) / 2, y - 16), lab, font=f, fill=WHITE)
        btn[name] = (x, y, 20)
    circle("ok", cx, 365, 42, "OK", "#4A1F6E")
    circle("replay", cx - 60, 530, 30, "↺")
    circle("star", cx + 60, 530, 30, "*")
    circle("rew", cx - 72, 620, 30, "◀◀")
    circle("play", cx, 620, 30, "▶ ‖")
    circle("ff", cx + 72, 620, 30, "▶▶")

    labels = {
        "back": ("left", "Back: página anterior (en Inicio, salir)"),
        "up": ("right", "Arriba / Abajo: mover línea por línea"),
        "left": ("left", "Izquierda: enlace anterior"),
        "right": ("right", "Derecha: enlace siguiente"),
        "ok": ("left", "OK: abrir el enlace seleccionado"),
        "replay": ("left", "Repetir: recargar la página"),
        "star": ("right", "Asterisco (*): abrir el menú"),
        "rew": ("left", "Retroceder: subir una pantalla"),
        "play": ("right", "Play: escribir dirección o búsqueda"),
        "ff": ("right", "Avanzar: bajar una pantalla"),
    }
    label_y = {"back": 150, "ok": 300, "left": 400, "replay": 540, "rew": 700,
               "up": 230, "right": 365, "star": 480, "play": 760, "ff": 600}
    f = font(R, 22)
    for name, (side, text) in labels.items():
        x, y, r = btn[name]
        ty = label_y[name]
        if side == "left":
            tw = d.textlength(text, font=f)
            tx = 440 - tw
            d.text((tx, ty - 13), text, font=f, fill="#1F2328")
            d.line([448, ty, x - r - 4, y], fill="#8C959F", width=2)
            d.ellipse([x - r - 8, y - 4, x - r, y + 4], fill="#8C959F")
        else:
            tx = 790
            d.text((tx, ty - 13), text, font=f, fill="#1F2328")
            if name == "play":  # entra por abajo para no cruzar el boton Avanzar
                d.line([tx - 8, ty, x, y + r + 4], fill="#8C959F", width=2)
                d.ellipse([x - 4, y + r, x + 4, y + r + 8], fill="#8C959F")
            else:
                d.line([tx - 8, ty, x + r + 4, y], fill="#8C959F", width=2)
                d.ellipse([x + r, y - 4, x + r + 8, y + 4], fill="#8C959F")
    im.save(os.path.join(OUT, "controles.png"))


def install_steps():
    W, H = 1500, 560
    im = Image.new("RGB", (W, H), "#FFFFFF")
    d = ImageDraw.Draw(im)
    center_text(d, 26, "Instalación en 3 pasos", font(B, 36), "#1F2328", W)
    steps = [
        ("1", "Activa modo desarrollador",
         ["En el control: Inicio ×3, Arriba ×2,", "Derecha, Izquierda, Derecha,", "Izquierda, Derecha.",
          "Anota la IP y crea tu contraseña."]),
        ("2", "Abre el instalador web",
         ["En la computadora, en la misma red:", "http://IP-DE-TU-ROKU", "Usuario: rokudev",
          "Contraseña: la que creaste."]),
        ("3", "Sube el ZIP",
         ["Upload → elige NavegadorWebRoku.zip", "(sin descomprimir).", "Install with zip.",
          "La app se abre sola en la TV."]),
    ]
    cw = 440
    for i, (n, title, lines) in enumerate(steps):
        x = 40 + i * (cw + 40)
        rounded(d, (x, 100, x + cw, 520), 18, fill="#F6F8FA", outline="#D0D7DE", width=2)
        d.ellipse([x + 30, 130, x + 100, 200], fill=PURPLE)
        f = font(B, 36)
        d.text((x + 65 - d.textlength(n, font=f) / 2, 142), n, font=f, fill=WHITE)
        d.text((x + 116, 150), title, font=font(B, 21), fill="#1F2328")
        # mini ilustracion
        if i == 0:
            rounded(d, (x + 60, 230, x + cw - 60, 340), 10, fill="#0B0B0D")
            t = "Developer Settings"
            d.text((x + cw / 2 - d.textlength(t, font=font(B, 22)) / 2, 258), t, font=font(B, 22), fill=WHITE)
            t = "http://192.168.1.27"
            d.text((x + cw / 2 - d.textlength(t, font=font(R, 20)) / 2, 296), t, font=font(R, 20), fill=LINK)
        elif i == 1:
            rounded(d, (x + 40, 230, x + cw - 40, 340), 10, fill="#FFFFFF", outline="#D0D7DE", width=2)
            d.rectangle([x + 40, 230, x + cw - 40, 262], fill="#EAEEF2")
            d.text((x + 56, 235), "http://192.168.1.27", font=font(R, 17), fill="#57606A")
            d.rectangle([x + 42, 272, x + cw - 42, 300], fill=PURPLE)
            t = "Development Application Installer"
            d.text((x + cw / 2 - d.textlength(t, font=font(B, 15)) / 2, 278), t, font=font(B, 15), fill=WHITE)
        else:
            for j, t in enumerate(["Upload", "Install with zip"]):
                f2 = font(B, 20)
                bx = x + 60 + j * 150
                bw = d.textlength(t, font=f2) + 40
                rounded(d, (bx, 260, bx + bw, 306), 23, fill=PURPLE)
                d.text((bx + 20, 270), t, font=f2, fill=WHITE)
        for k, line in enumerate(lines):
            d.text((x + 30, 370 + k * 34), line, font=font(R, 20), fill="#424A53")
        if i < 2:
            ax = x + cw + 6
            d.polygon([(ax, 300), (ax + 28, 310), (ax, 320)], fill="#8C959F")
    im.save(os.path.join(OUT, "instalacion.png"))


def architecture():
    W, H = 1400, 900
    im = Image.new("RGB", (W, H), "#FFFFFF")
    d = ImageDraw.Draw(im)
    center_text(d, 24, "Arquitectura de la app", font(B, 36), "#1F2328", W)

    def box(x, y, w, h, title, sub, fill, outline):
        rounded(d, (x, y, x + w, y + h), 14, fill=fill, outline=outline, width=2)
        d.text((x + 20, y + 16), title, font=font(B, 22), fill="#1F2328")
        for i, s in enumerate(sub):
            d.text((x + 20, y + 52 + i * 28), s, font=font(R, 18), fill="#424A53")

    def arrow(x1, y1, x2, y2, label="", lx=0, ly=0):
        d.line([x1, y1, x2, y2], fill="#57606A", width=3)
        import math
        a = math.atan2(y2 - y1, x2 - x1)
        p = [(x2, y2), (x2 - 16 * math.cos(a - 0.4), y2 - 16 * math.sin(a - 0.4)),
             (x2 - 16 * math.cos(a + 0.4), y2 - 16 * math.sin(a + 0.4))]
        d.polygon(p, fill="#57606A")
        if label:
            d.text((lx, ly), label, font=font(R, 17), fill="#57606A")

    box(40, 110, 300, 130, "Control remoto", ["onKeyEvent()", "OK, flechas, Back, *, Play"], "#FFF8E1", "#E3B341")
    box(420, 100, 520, 230, "MainScene", ["Interfaz: encabezado, lista, pie", "Historial (30 páginas)",
                                           "Teclado y menú (diálogos)", "Salto entre enlaces", "Mensajes de estado"],
        "#EEF4FF", "#2D6CDF")
    box(1020, 110, 340, 160, "LineItem", ["Una fila de la lista", "Colores por tipo:", "texto, título, enlace, nota"],
        "#EEF4FF", "#2D6CDF")
    box(420, 420, 520, 250, "BrowserTask (hilo aparte)", ["Descarga con roUrlTransfer (HTTPS)",
                                                          "Dirección o búsqueda → URL",
                                                          "Página de inicio y errores",
                                                          "Favoritos en el registro",
                                                          "Publica ContentNode a la escena"],
        "#EAF7EE", "#2DA44E")
    box(1020, 440, 340, 190, "HtmlParser.brs", ["HTML → líneas {t, k, u}", "Ignora script/style",
                                                "URLs relativas, entidades", "Ajuste a 80 caracteres"],
        "#EAF7EE", "#2DA44E")
    box(1020, 700, 340, 180, "AdFilter.brs", ["Oculta anuncios y patrocinios", "Quita enlaces de anuncios",
                                              "Limpia parámetros de rastreo", "Lee filtros.txt + Peter Lowe"],
        "#FFF1F0", "#CF222E")
    box(420, 720, 520, 140, "Registro del Roku", ["Favoritos, ajustes del bloqueo,", "sitios pausados"],
        "#F6F8FA", "#8C959F")
    box(40, 460, 300, 150, "Internet", ["Sitios web", "DuckDuckGo HTML", "(búsquedas)"], "#F6F8FA", "#8C959F")

    arrow(340, 175, 420, 190)
    arrow(940, 190, 1020, 190, "fila", 962, 160)
    arrow(640, 330, 640, 420, "input / action", 652, 360)
    arrow(740, 420, 740, 330, "content + result", 752, 384)
    arrow(940, 540, 1020, 540, "analiza", 948, 508)
    arrow(420, 535, 340, 535, "GET", 360, 500)
    arrow(1190, 630, 1190, 700, "filtra", 1202, 652)
    arrow(680, 670, 680, 720, "lee / guarda", 692, 682)
    im.save(os.path.join(OUT, "arquitectura.png"))


def app_icons():
    """Iconos y splash que van dentro del paquete (app/images)."""
    img = os.path.join(ROOT, "app", "images")
    os.makedirs(img, exist_ok=True)

    def icon(w, h, path):
        s = 4
        im = Image.new("RGB", (w * s, h * s), BAR)
        d = ImageDraw.Draw(im)
        d.rectangle([0, 0, w * s, h * s * 0.12], fill=FOCUS)
        globe(d, w * s / 2, h * s * 0.47, h * s * 0.27, max(6, int(h * s * 0.02)), LINK)
        f = font(B, int(h * s * 0.13))
        t = "Navegador Web"
        d.text(((w * s - d.textlength(t, font=f)) / 2, h * s * 0.80), t, font=f, fill=WHITE)
        im.resize((w, h), Image.LANCZOS).save(path)

    icon(290, 218, os.path.join(img, "icon_hd.png"))
    icon(540, 405, os.path.join(img, "icon_fhd.png"))
    im = Image.new("RGB", (1280, 720), BG)
    d = ImageDraw.Draw(im)
    globe(d, 640, 300, 110, 6, LINK)
    center_text(d, 450, "Navegador Web", font(B, 54), WHITE, 1280)
    center_text(d, 525, "para Roku", font(R, 26), GREY, 1280)
    im.save(os.path.join(img, "splash_hd.png"))
    Image.new("RGBA", (16, 16), (45, 108, 223, 255)).save(os.path.join(img, "focus.png"))
    return os.path.join(img, "icon_fhd.png")


if __name__ == "__main__":
    icon_path = app_icons()
    banner()
    framed(screen("Inicio", "", HOME_ROWS, 4, shield="Bloqueo: activo"), os.path.join(OUT, "pantalla-inicio.png"),
           "Simulación: pantalla de inicio con favoritos")
    framed(screen("Cómo funciona la televisión por internet",
                  "https://ejemplo.org/articulos/tv-por-internet", PAGE_ROWS, 7, "Guardado en favoritos",
                  shield="Bloqueados: 7  ·  Rastreo: 3"),
           os.path.join(OUT, "pantalla-pagina.png"),
           "Simulación: una página en modo lectura (el enlace enfocado se resalta)")
    framed(keyboard_screen(), os.path.join(OUT, "pantalla-teclado.png"),
           "Simulación: teclado para escribir dirección o búsqueda (botón Play)")
    framed(menu_screen(), os.path.join(OUT, "pantalla-menu.png"),
           "Simulación: menú de opciones (botón *)")
    framed(adblock_screen(), os.path.join(OUT, "pantalla-bloqueo.png"),
           "Simulación: submenú de bloqueo de anuncios (botón * → Bloqueo de anuncios)")
    before_after()
    remote()
    install_steps()
    architecture()
    Image.open(icon_path).save(os.path.join(OUT, "icono.png"))
    print("Imagenes generadas en", OUT)
