' Convierte HTML en una lista de lineas { t: texto, k: tipo, u: url }.
' Tipos: "t" texto, "h" encabezado, "l" enlace, "m" nota.
' Todas las funciones usan las tablas que setupParser() guarda en m.

sub setupParser()
    m.maxChars = 80        ' caracteres por linea
    m.maxLines = 1500      ' lineas por pagina
    m.maxBytes = 1500000   ' tamano maximo de HTML que se analiza

    m.reWs = CreateObject("roRegex", "\s+", "")
    m.reTagName = CreateObject("roRegex", "^/?[a-zA-Z][a-zA-Z0-9]*", "")
    m.reHref = CreateObject("roRegex", "(?:^|\s)href\s*=\s*(?:" + Chr(34) + "([^" + Chr(34) + "]*)" + Chr(34) + "|'([^']*)'|([^\s>]+))", "i")
    m.reAlt = CreateObject("roRegex", "(?:^|\s)alt\s*=\s*(?:" + Chr(34) + "([^" + Chr(34) + "]*)" + Chr(34) + "|'([^']*)'|([^\s>]+))", "i")
    m.reUrl = CreateObject("roRegex", "^(https?)://([^/?#]+)([^?#]*)", "i")
    m.reDir = CreateObject("roRegex", "^(.*/)", "")
    m.reScheme = CreateObject("roRegex", "^[a-zA-Z][a-zA-Z0-9+.\-]*:", "")
    m.reUddg = CreateObject("roRegex", "[?&]uddg=([^&]+)", "")
    m.reBinary = CreateObject("roRegex", "\.(jpe?g|png|gif|webp|bmp|ico|svg|mp4|mkv|avi|mov|webm|m3u8|mp3|ogg|wav|flac|pdf|zip|rar|7z|gz|tar|exe|msi|apk|iso|dmg|docx?|xlsx?|pptx?)(\?.*)?$", "i")

    m.skipTags = { script: 1, style: 1, svg: 1, noscript: 1, template: 1, textarea: 1, select: 1, iframe: 1, canvas: 1, video: 1, audio: 1 }
    m.blockTags = {
        p: 1, div: 1, br: 1, li: 1, ul: 1, ol: 1, tr: 1, table: 1, h1: 1, h2: 1, h3: 1, h4: 1, h5: 1, h6: 1,
        section: 1, article: 1, header: 1, footer: 1, nav: 1, main: 1, aside: 1, blockquote: 1, pre: 1, hr: 1,
        form: 1, dd: 1, dt: 1, dl: 1, figure: 1, figcaption: 1, address: 1, details: 1, summary: 1, body: 1,
        caption: 1, thead: 1, tbody: 1, fieldset: 1, button: 1
    }

    ' entidades HTML con nombre -> codigo Unicode (distingue mayusculas)
    m.ent = CreateObject("roAssociativeArray")
    m.ent.SetModeCaseSensitive()
    table = "amp=38,lt=60,gt=62,quot=34,apos=39,nbsp=32,iexcl=161,iquest=191,copy=169,reg=174,laquo=171,raquo=187,"
    table = table + "middot=183,bull=8226,hellip=8230,ndash=8211,mdash=8212,lsquo=8216,rsquo=8217,ldquo=8220,rdquo=8221,"
    table = table + "euro=8364,trade=8482,deg=176,times=215,rarr=8594,larr=8592,ordm=186,ordf=170,"
    table = table + "aacute=225,eacute=233,iacute=237,oacute=243,uacute=250,ntilde=241,uuml=252,ccedil=231,"
    table = table + "Aacute=193,Eacute=201,Iacute=205,Oacute=211,Uacute=218,Ntilde=209,Uuml=220,Ccedil=199,"
    table = table + "agrave=224,egrave=232,ograve=242,auml=228,ouml=246,atilde=227,otilde=245,acirc=226,ecirc=234,ocirc=244"
    for each pair in table.Split(",")
        kv = pair.Split("=")
        m.ent[kv[0]] = Val(kv[1], 10)
    end for
end sub

function newLine(text as string, kind as string, url as string) as object
    return { t: text, k: kind, u: url }
end function

' ------------------------------------------------------------------- analisis

function parseHtml(html as string, pageUrl as string, inlineLinks as boolean) as object
    st = {
        lines: [], buf: [], links: [], linkLen: 0, link: invalid,
        style: "t", prefix: "", title: "", inTitle: false,
        skip: "", inComment: false, base: parseBase(pageUrl),
        showInline: inlineLinks, full: false
    }

    ' Cada trozo (menos el primero) empieza con una etiqueta: "nombre atributos>texto"
    pieces = html.Split("<")
    first = true
    for each piece in pieces
        if first
            first = false
            addText(st, piece)
        else if st.skip <> ""
            ' dentro de <script>, <style>, etc.: ignorar todo hasta la etiqueta de cierre
            if LCase(Left(piece, Len(st.skip) + 1)) = "/" + st.skip
                st.skip = ""
                p = Instr(1, piece, ">")
                if p > 0 then addText(st, Mid(piece, p + 1))
            end if
        else if st.inComment
            p = Instr(1, piece, "-->")
            if p > 0
                st.inComment = false
                addText(st, Mid(piece, p + 3))
            end if
        else
            handlePiece(st, piece)
        end if

        if st.lines.Count() >= m.maxLines
            st.full = true
            exit for
        end if
    end for

    endLink(st)
    flushBlock(st)
    if st.full then st.lines.Push(newLine("--- Página recortada: es demasiado larga para mostrarla completa ---", "m", ""))

    title = cleanText(st.title)
    if title = "" then title = pageUrl
    if Len(title) > 90 then title = Left(title, 90)
    return { title: title, url: pageUrl, lines: st.lines }
end function

sub handlePiece(st as object, piece as string)
    if Left(piece, 3) = "!--"
        q = Instr(1, piece, "-->")
        if q > 0
            addText(st, Mid(piece, q + 3))
        else
            st.inComment = true
        end if
        return
    end if

    p = Instr(1, piece, ">")
    if p = 0
        addText(st, "<" + piece)   ' un "<" suelto en el texto
        return
    end if

    tag = Left(piece, p - 1)
    rest = Mid(piece, p + 1)

    found = m.reTagName.Match(tag)
    if found.Count() = 0
        c = Left(tag, 1)
        if c = "!" or c = "?"
            addText(st, rest)          ' <!DOCTYPE ...>, <?xml ...?>
        else
            addText(st, "<" + piece)   ' no era una etiqueta
        end if
        return
    end if

    name = LCase(found[0])
    closing = false
    if Left(name, 1) = "/"
        closing = true
        name = Mid(name, 2)
    end if

    if m.skipTags.DoesExist(name)
        if not closing and Right(tag, 1) <> "/"
            st.skip = name
        else
            addText(st, rest)
        end if
        return
    end if

    if name = "a"
        endLink(st)
        if not closing
            href = getAttr(m.reHref, tag)
            if href <> ""
                u = resolveUrl(st.base, decodeEntities(href))
                if u <> "" then st.link = { url: u, parts: [], alt: "", size: 0 }
            end if
        end if
    else if name = "title"
        st.inTitle = (not closing) and st.title = ""
    else if name = "img"
        if st.link <> invalid
            if st.link.alt = "" then st.link.alt = getAttr(m.reAlt, tag)
        end if
    else if name = "base"
        href = getAttr(m.reHref, tag)
        if m.reUrl.IsMatch(href) then st.base = parseBase(href)
    else if name = "td" or name = "th"
        addText(st, " ")
    else if m.blockTags.DoesExist(name)
        flushBlock(st)
        if Len(name) = 2 and Left(name, 1) = "h" and name <> "hr"
            if closing
                st.style = "t"
            else
                st.style = "h"
            end if
        else if name = "li" and not closing
            st.prefix = "• "
        end if
    end if

    addText(st, rest)
end sub

sub addText(st as object, s as string)
    if s = "" then return
    if st.inTitle
        st.title = st.title + s
        return
    end if
    st.buf.Push(s)
    if st.link <> invalid
        st.link.parts.Push(s)
        st.link.size = st.link.size + Len(s)
    end if
end sub

sub endLink(st as object)
    if st.link = invalid then return
    lk = st.link
    st.link = invalid

    text = cleanText(lk.parts.Join(""))
    st.linkLen = st.linkLen + Len(text)   ' solo cuenta el texto que tambien esta en el parrafo
    if text = "" then text = cleanText(lk.alt)
    if text = "" then text = "[enlace] " + lk.url
    if Len(text) > 200 then text = Left(text, 200) + "..."

    st.links.Push({ url: lk.url, text: text })
end sub

' Cierra el parrafo actual: primero su texto y debajo sus enlaces.
sub flushBlock(st as object)
    if st.link <> invalid
        ' un enlace que envuelve varios bloques (tarjetas): se mantiene junto
        if st.link.size < 600
            st.buf.Push(" ")
            st.link.parts.Push(" ")
            return
        end if
        endLink(st)
    end if

    text = cleanText(st.buf.Join(""))
    links = st.links
    linkLen = st.linkLen
    st.buf = []
    st.links = []
    st.linkLen = 0

    ' si el bloque es solo una lista de enlaces, no se repite su texto
    showText = text <> "" and (Len(text) - linkLen) > (3 * links.Count() + 2)
    if showText
        maxLen = m.maxChars
        if st.style = "h" then maxLen = m.maxChars - 12
        for each w in wrapText(st.prefix + text, maxLen)
            st.lines.Push(newLine(w, st.style, ""))
        end for
    end if
    st.prefix = ""

    if links.Count() > 0 and (st.showInline or not showText)
        seen = {}
        for each lk in links
            key = lk.url + "|" + lk.text
            if not seen.DoesExist(key)
                seen[key] = true
                isFirst = true
                for each w in wrapText(lk.text, m.maxChars - 4)
                    if isFirst
                        st.lines.Push(newLine("» " + w, "l", lk.url))
                        isFirst = false
                    else
                        st.lines.Push(newLine("   " + w, "l", lk.url))
                    end if
                end for
            end if
        end for
    end if
end sub

' -------------------------------------------------------------------- textos

function cleanText(s as string) as string
    if s = "" then return ""
    return m.reWs.ReplaceAll(decodeEntities(s), " ").Trim()
end function

function decodeEntities(s as string) as string
    if Instr(1, s, "&") = 0 then return s
    parts = s.Split("&")
    out = [parts[0]]
    for i = 1 to parts.Count() - 1
        p = parts[i]
        semi = Instr(1, p, ";")
        rep = invalid
        if semi > 1 and semi <= 10
            name = Left(p, semi - 1)
            if Left(name, 1) = "#"
                code = 0
                if LCase(Mid(name, 2, 1)) = "x"
                    code = Val(Mid(name, 3), 16)
                else
                    code = Val(Mid(name, 2), 10)
                end if
                if code = 160 or code = 9 or code = 10 or code = 13
                    rep = " "
                else if code >= 32 and code < 1114112
                    rep = Chr(code)
                end if
            else if m.ent.DoesExist(name)
                rep = Chr(m.ent[name])
            end if
        end if
        if rep <> invalid
            out.Push(rep)
            out.Push(Mid(p, semi + 1))
        else
            out.Push("&")
            out.Push(p)
        end if
    end for
    return out.Join("")
end function

function wrapText(text as string, maxLen as integer) as object
    lines = []
    if Len(text) <= maxLen
        lines.Push(text)
        return lines
    end if

    cur = ""
    for each word in text.Split(" ")
        w = word
        while Len(w) > maxLen
            if cur <> ""
                lines.Push(cur)
                cur = ""
            end if
            lines.Push(Left(w, maxLen))
            w = Mid(w, maxLen + 1)
        end while

        if cur = ""
            cur = w
        else if Len(cur) + 1 + Len(w) <= maxLen
            cur = cur + " " + w
        else
            lines.Push(cur)
            cur = w
        end if
    end for
    if cur <> "" then lines.Push(cur)
    return lines
end function

function getAttr(re as object, tag as string) as string
    found = re.Match(tag)
    for i = 1 to found.Count() - 1
        if found[i] <> invalid and found[i] <> "" then return found[i]
    end for
    return ""
end function

' ---------------------------------------------------------------- direcciones

function parseBase(url as string) as object
    base = { scheme: "https", origin: "", path: "/", dir: "/" }
    found = m.reUrl.Match(url)
    if found.Count() < 3 then return base

    base.scheme = LCase(found[1])
    base.origin = base.scheme + "://" + found[2]
    if found.Count() > 3 and found[3] <> "" then base.path = found[3]
    d = m.reDir.Match(base.path)
    if d.Count() > 1 then base.dir = d[1]
    return base
end function

' Convierte un href en una direccion absoluta. Devuelve "" si no se puede abrir.
function resolveUrl(base as object, href as string) as string
    h = href.Trim()
    if h = "" then return ""
    c = Left(h, 1)
    if c = "#" then return ""

    lower = LCase(Left(h, 8))
    if Left(lower, 7) = "http://" or lower = "https://"
        u = h
    else if Left(h, 2) = "//"
        u = base.scheme + ":" + h
    else if m.reScheme.IsMatch(h)
        return ""   ' javascript:, mailto:, tel:, data:, etc.
    else if base.origin = ""
        return ""
    else if c = "/"
        u = base.origin + h
    else if c = "?"
        u = base.origin + base.path + h
    else
        u = base.origin + base.dir + h
    end if

    hash = Instr(1, u, "#")
    if hash > 0 then u = Left(u, hash - 1)
    if Instr(1, u, "/.") > 0 then u = removeDots(u)
    if Instr(1, u, " ") > 0 then u = u.Replace(" ", "%20")

    ' los resultados de DuckDuckGo pasan por un redirector: usar el destino real
    if Instr(1, u, "duckduckgo.com/l/?") > 0
        found = m.reUddg.Match(u)
        if found.Count() > 1
            target = found[1].DecodeUriComponent()
            if m.reUrl.IsMatch(target) then u = target
        end if
    end if
    return u
end function

function removeDots(u as string) as string
    found = m.reUrl.Match(u)
    if found.Count() < 4 then return u
    origin = found[1] + "://" + found[2]
    path = found[3]
    tail = Mid(u, Len(found[0]) + 1)   ' ?consulta

    stack = []
    for each seg in path.Split("/")
        if seg = ".."
            if stack.Count() > 1 then stack.Pop()
        else if seg <> "."
            stack.Push(seg)
        end if
    end for
    return origin + stack.Join("/") + tail
end function
