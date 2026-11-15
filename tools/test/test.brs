' Prueba del analizador HTML con el interprete brs:  npm test
' Analiza sample.html e imprime cada linea como [tipo] texto -> url
sub main()
    setupParser()
    html = ReadAsciiFile("pkg:/sample.html")
    page = parseHtml(html, "https://www.sitio.com/seccion/sub/index.html?q=1", true)
    print "TITULO: "; page.title
    for each ln in page.lines
        print "["; ln.k; "] "; ln.t; "   -> "; ln.u
    end for

    page = parseHtml(html, "https://www.sitio.com/seccion/sub/index.html", false)
    print "Lineas sin enlaces en parrafos: "; page.lines.Count()
    print "wrapText: "; FormatJson(wrapText("aaaa bbbb cccc dddddddddddddd ee", 9))
end sub
