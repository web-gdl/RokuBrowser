' Bloqueo de anuncios, rastreadores y contenido patrocinado.
'
' Capas (todas actuan sobre el HTML ya descargado; el navegador nunca ejecuta
' scripts ni carga imagenes, asi que los anuncios no llegan a "correr"):
'   1. Elementos: oculta bloques cuya clase, id o atributos son de anuncios,
'      patrocinios o avisos de cookies (como los filtros cosmeticos de uBlock).
'   2. Enlaces: quita enlaces a redes de anuncios y rastreo, y bloquea abrirlos.
'   3. Rastreo: limpia parametros como utm_*, fbclid o gclid y desenvuelve
'      redirectores de Google y Facebook (como Ghostery).
'   4. Etiquetas: quita textos sueltos como "Publicidad" o "Contenido patrocinado".
'
' Se usa junto con HtmlParser.brs: comparten m.reUrl, m.reWs, m.skipTags, etc.

sub setupFilters(active as boolean, listText as string)
    m.stats = { hidden: 0, links: 0, labels: 0, trackers: 0 }
    m.flt = { on: active, cosmetic: active, domains: {}, allow: {}, paths: [], classes: {}, ids: {}, rules: 0 }

    q = Chr(34)
    attrPattern = "\s*=\s*(?:" + q + "([^" + q + "]*)" + q + "|'([^']*)'|([^\s>]+))"
    m.reClass = CreateObject("roRegex", "(?:^|\s)class" + attrPattern, "i")
    m.reId = CreateObject("roRegex", "(?:^|\s)id" + attrPattern, "i")

    ' palabras de anuncio dentro de una clase o id, separadas por espacio, - o _
    words = "ad|ads|advert|adverts|advertisement|advertisements|advertising|adsbygoogle|adslot|adunit|adbox|adbanner|adcontainer|adwrapper|"
    words = words + "sponsor|sponsors|sponsored|sponsorship|promoted|publicidad|publi|patrocinado|patrocinados|patrocinio|anuncio|anuncios|"
    words = words + "taboola|outbrain|dfp|cookie|cookies|consent|gdpr|onetrust|didomi|cookiebot"
    m.reAdToken = CreateObject("roRegex", "(^|[\s_\-])(" + words + ")($|[\s_\-0-9])", "i")

    m.reAdAttr = CreateObject("roRegex", "\s(data-ad|data-ad-slot|data-ad-client|data-adunit|data-ad-unit|data-ad-format|data-native-ad|data-sponsored|data-google-query-id)(\s*=|[\s/]|$)|\saria-label\s*=\s*[" + q + "']?\s*(advertisement|advertising|publicidad|anuncio|anuncios|sponsored|patrocinado|ad)[" + q + "'\s>]", "i")

    labels = "publicidad|anuncio|anuncios|advertisement|advertisements|advertising|ad|ads|sponsored|sponsored content|sponsored post|"
    labels = labels + "patrocinado|contenido patrocinado|promocionado|contenido promocionado|paid content|paid post|promoted|publi|"
    labels = labels + "espacio publicitario|continúa leyendo después del anuncio|continúa después de la publicidad|"
    labels = labels + "la nota continúa después de la publicidad|story continues below advertisement|article continues below advertisement|"
    labels = labels + "continue reading below|scroll to continue with content"
    m.reAdLabel = CreateObject("roRegex", "^(" + labels + ")[\s.:]*$", "i")

    m.reSimpleName = CreateObject("roRegex", "^[a-z0-9_\-]+$", "")
    m.reDomain = CreateObject("roRegex", "^[a-z0-9]([a-z0-9\-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]*[a-z0-9])?)*\.[a-z]{2,}$", "")
    m.reRedirect = CreateObject("roRegex", "^https?://(www\.)?google\.[a-z.]+/url\?|^https?://lm?\.(facebook|instagram)\.com/l\.php\?|^https?://(www\.)?youtube\.com/redirect\?", "i")

    m.hideable = {
        div: 1, section: 1, aside: 1, ins: 1, article: 1, figure: 1, ul: 1, ol: 1, li: 1, span: 1,
        table: 1, header: 1, footer: 1, form: 1, a: 1, p: 1, center: 1, dl: 1, nav: 1
    }

    m.trackParams = {}
    for each name in ["fbclid", "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "msclkid", "twclid", "ttclid", "yclid", "mc_cid", "mc_eid", "igshid", "igsh", "_ga", "_gl", "_hsenc", "_hsmi", "mkt_tok", "oly_anon_id", "oly_enc_id", "vero_id", "ref_src", "s_kwcid", "ef_id", "srsltid", "rb_clickid", "epik", "ncid", "cmpid", "icid", "si"]
        m.trackParams[name] = true
    end for

    if not active then return
    for each raw in listText.Split(Chr(10))
        addFilterRule(raw.Trim())
    end for
end sub

' Agrega una linea de una lista de filtros (sintaxis ABP, archivo hosts o un dominio por linea).
sub addFilterRule(ln as string)
    if ln = "" then return
    c = Left(ln, 1)
    if c = "!" or c = "[" then return

    if Left(ln, 3) = "###"
        name = LCase(Mid(ln, 4))
        if m.reSimpleName.IsMatch(name)
            m.flt.ids[name] = true
            m.flt.rules = m.flt.rules + 1
        end if
        return
    end if
    if Left(ln, 3) = "##."
        name = LCase(Mid(ln, 4))
        if m.reSimpleName.IsMatch(name)
            m.flt.classes[name] = true
            m.flt.rules = m.flt.rules + 1
        end if
        return
    end if
    if c = "#" then return   ' comentario de archivo hosts u otro filtro cosmetico no compatible

    if Left(ln, 4) = "@@||"
        d = ruleBody(Mid(ln, 5))
        if d <> "" and Instr(1, d, "/") = 0 then m.flt.allow[d] = true
        return
    end if

    if Left(ln, 2) = "||"
        body = ruleBody(Mid(ln, 3))
        if body = "" then return
        slash = Instr(1, body, "/")
        if slash > 1
            m.flt.paths.Push({ d: Left(body, slash - 1), p: Mid(body, slash) })
        else
            m.flt.domains[body] = true
        end if
        m.flt.rules = m.flt.rules + 1
        return
    end if

    ' archivo hosts ("0.0.0.0 dominio") o un dominio por linea
    parts = m.reWs.Split(ln)
    d = LCase(parts[parts.Count() - 1])
    if m.reDomain.IsMatch(d)
        m.flt.domains[d] = true
        m.flt.rules = m.flt.rules + 1
    end if
end sub

' "dominio.com^" -> "dominio.com"; devuelve "" si la regla tiene opciones ($...)
function ruleBody(s as string) as string
    if Instr(1, s, "$") > 0 then return ""
    p = Instr(1, s, "^")
    if p > 0 then s = Left(s, p - 1)
    return LCase(s.Trim())
end function

' ------------------------------------------------------------------- enlaces

function urlHost(url as string) as string
    found = m.reUrl.Match(url)
    if found.Count() < 3 then return ""
    host = LCase(found[2])
    at = Instr(1, host, "@")
    if at > 0 then host = Mid(host, at + 1)
    colon = Instr(1, host, ":")
    if colon > 0 then host = Left(host, colon - 1)
    return host
end function

' Nombre del sitio para pausar el bloqueo: sin "www."
function siteKey(url as string) as string
    host = urlHost(url)
    if Left(host, 4) = "www." then host = Mid(host, 5)
    return host
end function

function isBlockedUrl(url as string) as boolean
    if not m.flt.on then return false
    host = urlHost(url)
    if host = "" then return false

    h = host
    while h <> ""
        if m.flt.allow.DoesExist(h) then return false
        if m.flt.domains.DoesExist(h) then return true
        p = Instr(1, h, ".")
        if p = 0 then exit while
        h = Mid(h, p + 1)
    end while

    if m.flt.paths.Count() > 0
        found = m.reUrl.Match(url)
        path = "/"
        if found.Count() > 3 and found[3] <> "" then path = found[3]
        for each r in m.flt.paths
            if host = r.d or Right(host, Len(r.d) + 1) = "." + r.d
                if Left(path, Len(r.p)) = r.p then return true
            end if
        end for
    end if
    return false
end function

' Quita parametros de rastreo y desenvuelve redirectores conocidos.
function cleanUrl(url as string) as string
    u = url
    if m.reRedirect.IsMatch(u)
        target = queryParam(u, ["q", "url", "u"])
        if target <> "" and m.reUrl.IsMatch(target)
            u = target
            m.stats.trackers = m.stats.trackers + 1
        end if
    end if

    q = Instr(1, u, "?")
    if q = 0 then return u
    kept = []
    removed = false
    for each p in Mid(u, q + 1).Split("&")
        if p <> ""
            eq = Instr(1, p, "=")
            name = p
            if eq > 0 then name = Left(p, eq - 1)
            name = LCase(name)
            if Left(name, 4) = "utm_" or m.trackParams.DoesExist(name)
                removed = true
            else
                kept.Push(p)
            end if
        end if
    end for
    if not removed then return u

    m.stats.trackers = m.stats.trackers + 1
    if kept.Count() = 0 then return Left(u, q - 1)
    return Left(u, q - 1) + "?" + kept.Join("&")
end function

function queryParam(url as string, names as object) as string
    q = Instr(1, url, "?")
    if q = 0 then return ""
    for each p in Mid(url, q + 1).Split("&")
        eq = Instr(1, p, "=")
        if eq > 1
            name = LCase(Left(p, eq - 1))
            for each n in names
                if name = n then return Mid(p, eq + 1).DecodeUriComponent()
            end for
        end if
    end for
    return ""
end function

function isAdLabel(text as string) as boolean
    return m.flt.cosmetic and Len(text) < 80 and m.reAdLabel.IsMatch(text)
end function

' ------------------------------------------------------------------ elementos

function isAdElement(tag as string) as boolean
    if Instr(1, tag, "=") = 0 then return false

    if Instr(1, tag, "data-") > 0 or Instr(1, tag, "aria-label") > 0
        if m.reAdAttr.IsMatch(tag) then return true
    end if

    if Instr(1, tag, "class") > 0
        v = getAttr(m.reClass, tag)
        if v <> ""
            if m.reAdToken.IsMatch(v) then return true
            for each c in m.reWs.Split(LCase(v))
                if m.flt.classes.DoesExist(c) then return true
            end for
        end if
    end if

    if Instr(1, tag, "id") > 0
        v = getAttr(m.reId, tag)
        if v <> ""
            if m.reAdToken.IsMatch(v) then return true
            if m.flt.ids.DoesExist(LCase(v.Trim())) then return true
        end if
    end if
    return false
end function

' Empieza a ocultar un elemento; termina cuando se cierra (ver hidePiece).
sub startHide(st as object, name as string, tag as string)
    m.stats.hidden = m.stats.hidden + 1
    if Right(tag, 1) = "/" then return   ' <div ... /> no tiene contenido
    if name = "a" then endLink(st)
    if m.blockTags.DoesExist(name) then flushBlock(st)
    st.hide = name
    st.hideDepth = 1
    st.hideCount = 0
end sub

' Procesa una etiqueta dentro de un elemento oculto: solo cuenta aperturas y
' cierres del mismo nombre para saber donde termina.
sub hidePiece(st as object, piece as string)
    st.hideCount = st.hideCount + 1
    if st.hideCount > 5000
        st.hide = ""   ' nunca se cerro: dejar de ocultar
        handlePiece(st, piece)
        return
    end if

    if Left(piece, 3) = "!--"
        if Instr(1, piece, "-->") = 0 then st.inComment = true
        return
    end if

    found = m.reTagName.Match(piece)
    if found.Count() = 0 then return
    name = LCase(found[0])
    closing = Left(name, 1) = "/"
    if closing then name = Mid(name, 2)
    p = Instr(1, piece, ">")
    selfClosing = p > 1 and Mid(piece, p - 1, 1) = "/"

    if not closing and not selfClosing and m.skipTags.DoesExist(name)
        st.skip = name   ' un <script> dentro del anuncio puede traer "<div" en texto
        return
    end if

    if closing and (name = "body" or name = "html")
        st.hide = ""
        handlePiece(st, piece)
        return
    end if

    ' <li> y <p> pueden quedar sin cerrar: el siguiente hermano o el cierre del padre los termina
    if (st.hide = "li" or st.hide = "p") and st.hideDepth = 1
        implicitEnd = false
        if not closing and name = st.hide then implicitEnd = true
        if closing and name <> st.hide and m.blockTags.DoesExist(name) then implicitEnd = true
        if implicitEnd
            st.hide = ""
            handlePiece(st, piece)
            return
        end if
    end if

    if name = st.hide
        if closing
            st.hideDepth = st.hideDepth - 1
            if st.hideDepth = 0
                st.hide = ""
                if m.blockTags.DoesExist(name) then flushBlock(st)
                if p > 0 then addText(st, Mid(piece, p + 1))
            end if
        else if not selfClosing
            st.hideDepth = st.hideDepth + 1
        end if
    end if
end sub
