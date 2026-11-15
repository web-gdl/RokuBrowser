' Pruebas del analizador HTML y del bloqueo de anuncios:  npm test
' Se ejecuta con el interprete brs desde la raiz del repositorio (pkg:/ = raiz).
sub main()
    m.fails = 0
    m.oks = 0
    setupParser()

    ' --- analizador sin filtros
    html = ReadAsciiFile("pkg:/tools/test/sample.html")
    page = parseHtml(html, "https://www.sitio.com/seccion/sub/index.html?q=1", true)
    print "TITULO: "; page.title
    printLines(page.lines)
    all = joinLines(page.lines)
    check("titulo con entidades", page.title = "Prueba & título")
    check("script oculto", Instr(1, all, "NO DEBE VERSE") = 0)
    check("noscript oculto", Instr(1, all, "NOSCRIPT") = 0)
    check("url relativa con ..", Instr(1, all, "https://www.sitio.com/seccion/otra/pagina.html?x=1&y=2") > 0)
    check("redirector de DuckDuckGo", Instr(1, all, "https://es.wikipedia.org/wiki/Roku") > 0)
    check("sin javascript:", Instr(1, all, "javascript") = 0)
    check("wrapText", FormatJson(wrapText("aaaa bbbb cccc dddddddddddddd ee", 9)) = FormatJson(["aaaa bbbb", "cccc", "ddddddddd", "ddddd ee"]))

    ' --- pagina con anuncios, filtros apagados
    ads = ReadAsciiFile("pkg:/tools/test/anuncios.html")
    off = parseHtml(ads, "https://www.diario.mx/nota/1", true)
    offText = joinLines(off.lines)
    check("sin filtros se ve el anuncio", Instr(1, offText, "ANUNCIO DIV") > 0)

    ' --- con filtros
    setupFilters(true, ReadAsciiFile("pkg:/app/filters/filtros.txt"))
    print "Reglas cargadas: "; m.flt.rules
    page = parseHtml(ads, "https://www.diario.mx/nota/1", true)
    print "--- con bloqueo"
    printLines(page.lines)
    print "Estadisticas: "; FormatJson(m.stats)
    t = joinLines(page.lines)
    check("aviso de cookies oculto", Instr(1, t, "cookies") = 0)
    check("div de anuncio anidado oculto", Instr(1, t, "ANUNCIO DIV") = 0 and Instr(1, t, "Compra ya") = 0)
    check("texto posterior al anuncio visible", Instr(1, t, "Primer párrafo real") > 0)
    check("parametros de rastreo quitados", Instr(1, t, "https://www.ejemplo.com/nota?page=2") > 0)
    check("utm quitado y otro parametro conservado", Instr(1, t, "https://www.diario.mx/deportes?id=7") > 0)
    check("etiqueta Publicidad quitada", Instr(1, t, "Publicidad") = 0)
    check("taboola por id y por clase", Instr(1, t, "Truco") = 0 and Instr(1, t, "TABOOLA") = 0)
    check("li patrocinado sin cerrar", Instr(1, t, "LI PATROCINADO") = 0 and Instr(1, t, "Nota relacionada real") > 0 and Instr(1, t, "Otra nota real") > 0)
    check("redirector de Google desenvuelto", Instr(1, t, "https://destino.org/pagina") > 0)
    check("redirector de Facebook y gclid", Instr(1, t, "https://sitio.mx/a ") > 0 or Instr(1, t, "-> https://sitio.mx/a" + Chr(10)) > 0)
    check("clic de anuncio de Bing quitado", Instr(1, t, "bing.com") = 0)
    check("subdominio de doubleclick quitado", Instr(1, t, "doubleclick") = 0)
    check("resultado pagado de DuckDuckGo", Instr(1, t, "RESULTADO PAGADO") = 0)
    check("aria-label Advertisement", Instr(1, t, "ARIA AD") = 0)
    check("clases legitimas visibles", Instr(1, t, "Elementos legítimos") > 0)
    check("parrafo final visible", Instr(1, t, "Último párrafo real") > 0 and Instr(1, t, "Pie de página") > 0)

    check("bloquea dominio", isBlockedUrl("https://ads.pubmatic.com/x"))
    check("bloquea ruta", isBlockedUrl("https://duckduckgo.com/y.js?a=1"))
    check("no bloquea el buscador", not isBlockedUrl("https://html.duckduckgo.com/html/?q=roku"))
    check("no bloquea dominio parecido", not isBlockedUrl("https://notdoubleclick.net/"))
    check("siteKey", siteKey("https://www.Diario.mx:443/a") = "diario.mx")

    addFilterRule("0.0.0.0 tracker-de-prueba.com")
    addFilterRule("@@||ads.ejemplo-permitido.com^")
    addFilterRule("||ejemplo-permitido.com^")
    check("formato hosts", isBlockedUrl("http://tracker-de-prueba.com/p"))
    check("excepcion @@", not isBlockedUrl("https://ads.ejemplo-permitido.com/") and isBlockedUrl("https://www.ejemplo-permitido.com/"))

    ' --- una pagina envuelta en un contenedor con clase de anuncio
    wrapped = "<html><body><div class=" + Chr(34) + "ad-free-layout" + Chr(34) + "><p>Contenido completo de la página.</p><p>Segundo párrafo.</p></div></body></html>"
    page = parseHtml(wrapped, "https://x.com/", true)
    check("detecta pagina vaciada por el filtro", page.lines.Count() = 0 and m.stats.hidden > 0)

    print ""
    ' run.sh lee esta linea para decidir si la prueba paso
    print "PRUEBAS: "; m.oks; " correctas, "; m.fails; " fallidas"
end sub

sub check(name as string, ok as boolean)
    if ok
        m.oks = m.oks + 1
    else
        m.fails = m.fails + 1
        print "FALLA: "; name
    end if
end sub

function joinLines(lines as object) as string
    out = []
    for each ln in lines
        out.Push(ln.t + " -> " + ln.u)
    end for
    return out.Join(Chr(10)) + Chr(10)
end function

sub printLines(lines as object)
    for each ln in lines
        print "["; ln.k; "] "; ln.t; "   -> "; ln.u
    end for
end sub
