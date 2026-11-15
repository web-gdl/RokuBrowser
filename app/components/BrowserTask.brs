sub init()
    m.top.functionName = "runTask"
end sub

sub runTask()
    setupParser()
    if m.top.action = "bookmark"
        toggleBookmark(m.top.input, m.top.pageTitle)
    else
        loadPage(m.top.input)
    end if
end sub

' -------------------------------------------------------------------- cargar

sub loadPage(request as string)
    s = request.Trim()
    if s = "app:home"
        publish(homePage())
        return
    end if

    url = toUrl(s)

    if m.reBinary.IsMatch(url)
        publish(messagePage(url, "Archivo no compatible", ["Este enlace apunta a una imagen, video o archivo descargable.", "El navegador solo puede mostrar páginas de texto."]))
        return
    end if

    resp = httpGet(url)
    if not resp.ok
        publish(messagePage(url, "No se pudo cargar la página", [resp.error, "Revisa la dirección y la conexión a internet del televisor."]))
        return
    end if

    ct = LCase(resp.contentType)
    body = resp.body
    if Len(body) > m.maxBytes then body = Left(body, m.maxBytes)

    if ct <> "" and Instr(1, ct, "html") = 0 and Instr(1, ct, "text/") = 0 and Instr(1, ct, "xml") = 0 and Instr(1, ct, "json") = 0
        publish(messagePage(url, "Contenido no compatible", ["Tipo de contenido: " + ct, "El navegador solo puede mostrar páginas de texto."]))
        return
    end if

    isHtml = Instr(1, ct, "html") > 0
    if not isHtml and Instr(1, ct, "text/plain") = 0 and Instr(1, ct, "json") = 0
        head = LCase(Left(body, 2000))
        isHtml = Instr(1, head, "<html") > 0 or Instr(1, head, "<!doctype") > 0 or Instr(1, head, "<body") > 0
    end if

    if isHtml
        page = parseHtml(body, url, m.top.inlineLinks)
    else
        page = plainPage(body, url)
    end if

    if resp.code >= 400
        page.lines.Unshift(newLine("El servidor respondió con el error HTTP " + resp.code.ToStr(), "m", ""))
    end if

    if page.lines.Count() < 2
        page.lines.Push(newLine("Esta página no tiene texto legible.", "h", ""))
        for each t in wrapText("Probablemente necesita JavaScript para mostrar su contenido, y Roku no puede ejecutarlo. Prueba con otra página o con una versión ligera del sitio.", m.maxChars)
            page.lines.Push(newLine(t, "t", ""))
        end for
        page.lines.Push(newLine("» Ir al inicio", "l", "app:home"))
    end if

    publish(page)
end sub

' Texto escrito por el usuario -> direccion. Sin punto o con espacios = busqueda.
function toUrl(s as string) as string
    lower = LCase(s)
    if Left(lower, 7) = "http://" or Left(lower, 8) = "https://" then return s
    if Instr(1, s, " ") = 0 and Instr(1, s, ".") > 0 then return "https://" + s
    return "https://html.duckduckgo.com/html/?q=" + s.EncodeUriComponent()
end function

function httpGet(url as string) as object
    result = { ok: false, error: "", code: 0, body: "", contentType: "" }

    xfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    xfer.SetMessagePort(port)
    xfer.SetUrl(url)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.EnableEncodings(true)
    xfer.EnableCookies()
    xfer.RetainBodyOnError(true)
    xfer.AddHeader("User-Agent", "Mozilla/5.0 (Linux; Roku) NavegadorRoku/1.0")
    xfer.AddHeader("Accept", "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.5")
    xfer.AddHeader("Accept-Language", "es-MX,es;q=0.9,en;q=0.6")

    if not xfer.AsyncGetToString()
        result.error = "No se pudo iniciar la conexión."
        return result
    end if

    msg = wait(25000, port)
    if type(msg) <> "roUrlEvent"
        xfer.AsyncCancel()
        result.error = "El servidor tardó demasiado en responder."
        return result
    end if

    code = msg.GetResponseCode()
    result.code = code
    if code < 0
        result.error = "Error de red: " + msg.GetFailureReason()
        return result
    end if

    body = msg.GetString()
    if body = invalid then body = ""
    result.body = body

    headers = msg.GetResponseHeaders()
    if headers <> invalid and headers["content-type"] <> invalid
        result.contentType = headers["content-type"]
    end if

    if body = "" and code >= 400
        result.error = "El servidor respondió con el error HTTP " + code.ToStr()
        return result
    end if

    result.ok = true
    return result
end function

' ----------------------------------------------------------- paginas propias

function homePage() as object
    lines = []
    lines.Push(newLine("Navegador Web para Roku", "h", ""))
    lines.Push(newLine("» Escribir una dirección o buscar en la web", "l", "app:input"))
    lines.Push(newLine("Favoritos", "h", ""))
    for each b in readBookmarks()
        lines.Push(newLine("» " + b.title, "l", b.url))
    end for
    lines.Push(newLine("Controles", "h", ""))
    help = [
        "Arriba / Abajo: moverse por la página, línea por línea.",
        "OK: abrir el enlace seleccionado (los enlaces se ven en azul).",
        "Izquierda / Derecha: saltar al enlace anterior o siguiente.",
        "Retroceder / Avanzar: subir o bajar una pantalla completa.",
        "Play: escribir una dirección o una búsqueda.",
        "Asterisco (*): menú con inicio, recargar y favoritos.",
        "Back: página anterior. En esta pantalla, sale del navegador.",
        "Este navegador muestra el texto y los enlaces de las páginas.",
        "No puede mostrar imágenes, video ni sitios que dependen de JavaScript."
    ]
    for each h in help
        lines.Push(newLine(h, "m", ""))
    end for
    return { title: "Inicio", url: "app:home", lines: lines }
end function

function messagePage(url as string, heading as string, texts as object) as object
    lines = [newLine(heading, "h", "")]
    for each t in texts
        for each w in wrapText(t, m.maxChars)
            lines.Push(newLine(w, "t", ""))
        end for
    end for
    for each w in wrapText(url, m.maxChars)
        lines.Push(newLine(w, "m", ""))
    end for
    lines.Push(newLine("» Reintentar", "l", url))
    lines.Push(newLine("» Ir al inicio", "l", "app:home"))
    return { title: heading, url: url, lines: lines }
end function

function plainPage(body as string, url as string) as object
    lines = []
    for each raw in body.Split(Chr(10))
        text = m.reWs.ReplaceAll(raw, " ").Trim()
        if text <> ""
            for each w in wrapText(text, m.maxChars)
                lines.Push(newLine(w, "t", ""))
            end for
        end if
        if lines.Count() >= m.maxLines then exit for
    end for
    return { title: url, url: url, lines: lines }
end function

' Convierte las lineas en nodos y entrega el resultado a la escena.
sub publish(page as object)
    root = CreateObject("roSGNode", "ContentNode")
    kids = []
    links = []
    i = 0
    for each ln in page.lines
        n = CreateObject("roSGNode", "ContentNode")
        n.setFields({ title: ln.t, url: ln.u, shortDescriptionLine1: ln.k })
        kids.Push(n)
        if ln.u <> "" then links.Push(i)
        i = i + 1
    end for
    root.appendChildren(kids)

    m.top.content = root
    m.top.result = { url: page.url, title: page.title, links: links }
end sub

' ----------------------------------------------------------------- favoritos

function readBookmarks() as object
    sec = CreateObject("roRegistrySection", "navegador")
    if sec.Exists("bookmarks")
        list = ParseJson(sec.Read("bookmarks"))
        if type(list) = "roArray" then return list
    end if
    return [
        { title: "Buscar en DuckDuckGo", url: "https://html.duckduckgo.com/html/" },
        { title: "Wikipedia en español", url: "https://es.m.wikipedia.org/" },
        { title: "BBC News Mundo", url: "https://www.bbc.com/mundo" },
        { title: "CNN Lite (inglés)", url: "https://lite.cnn.com/" },
        { title: "NPR Text (inglés)", url: "https://text.npr.org/" },
        { title: "Hacker News (inglés)", url: "https://news.ycombinator.com/" }
    ]
end function

sub toggleBookmark(url as string, title as string)
    list = readBookmarks()
    found = -1
    for i = 0 to list.Count() - 1
        if list[i].url = url
            found = i
            exit for
        end if
    end for

    if found >= 0
        list.Delete(found)
        message = "Quitado de favoritos"
    else
        t = title.Trim()
        if t = "" then t = url
        if Len(t) > 60 then t = Left(t, 60)
        list.Push({ title: t, url: url })
        message = "Guardado en favoritos"
    end if

    sec = CreateObject("roRegistrySection", "navegador")
    sec.Write("bookmarks", FormatJson(list))
    sec.Flush()
    m.top.result = { message: message }
end sub
