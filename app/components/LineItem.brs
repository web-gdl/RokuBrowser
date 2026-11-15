sub init()
    m.label = m.top.findNode("text")

    m.fontNormal = CreateObject("roSGNode", "Font")
    m.fontNormal.uri = "font:SystemFontFile"
    m.fontNormal.size = 22

    m.fontBold = CreateObject("roSGNode", "Font")
    m.fontBold.uri = "font:BoldSystemFontFile"
    m.fontBold.size = 22

    m.label.font = m.fontNormal
end sub

' kind (shortDescriptionLine1): "t" texto, "h" encabezado, "l" enlace, "m" nota
sub refresh()
    c = m.top.itemContent
    if c = invalid then return

    kind = c.shortDescriptionLine1
    m.label.text = c.title

    if kind = "h"
        m.label.font = m.fontBold
    else
        m.label.font = m.fontNormal
    end if

    if m.top.itemHasFocus
        m.label.color = "0xFFFFFFFF"
    else if kind = "l"
        m.label.color = "0x7FB8FFFF"
    else if kind = "h"
        m.label.color = "0xFFD166FF"
    else if kind = "m"
        m.label.color = "0x9AA5B1FF"
    else
        m.label.color = "0xE8EAEDFF"
    end if
end sub
