' Navegador Web para Roku - escena principal.
' Toda la red y el registro se hacen en BrowserTask; aqui solo interfaz y control remoto.

sub init()
    m.top.backgroundColor = "0x101820FF"
    m.top.backgroundURI = ""

    m.list = m.top.findNode("list")
    m.title = m.top.findNode("title")
    m.urlLabel = m.top.findNode("url")
    m.status = m.top.findNode("status")
    m.loadingGroup = m.top.findNode("loading")
    m.statusTimer = m.top.findNode("statusTimer")

    m.history = []        ' paginas anteriores (para Back)
    m.current = invalid   ' { url, title, content, links, index }
    m.task = invalid
    m.bmTask = invalid
    m.dialog = invalid
    m.loading = false
    m.pendingPush = false
    m.pendingIndex = 0
    m.showInline = true   ' mostrar enlaces que estan dentro de parrafos

    m.list.observeField("itemSelected", "onItemSelected")
    m.statusTimer.observeField("fire", "onStatusTimer")
    m.list.setFocus(true)

    navigate("app:home", false)
end sub

' ---------------------------------------------------------------- navegacion

sub navigate(target as string, push as boolean, restoreIndex = 0 as integer)
    if target = "app:input"
        showKeyboard()
        return
    end if

    cancelTask()
    m.pendingPush = push
    m.pendingIndex = restoreIndex
    setLoading(true)

    t = CreateObject("roSGNode", "BrowserTask")
    t.action = "load"
    t.input = target
    t.inlineLinks = m.showInline
    t.observeField("result", "onPageLoaded")
    m.task = t
    t.control = "RUN"
end sub

sub cancelTask()
    if m.task <> invalid
        m.task.unobserveField("result")
        m.task.control = "STOP"
        m.task = invalid
    end if
    setLoading(false)
end sub

sub setLoading(active as boolean)
    m.loading = active
    m.loadingGroup.visible = active
end sub

sub onPageLoaded(event as object)
    task = event.getRoSGNode()
    if m.task = invalid or not task.isSameNode(m.task) then return

    res = event.getData()
    content = task.content
    m.task = invalid
    setLoading(false)
    if res = invalid or content = invalid then return

    if m.pendingPush and m.current <> invalid
        m.current.index = focusedIndex()
        m.history.push(m.current)
        trimHistory()
    end if

    m.current = { url: res.url, title: res.title, content: content, links: res.links, index: 0 }
    showCurrent(m.pendingIndex)
end sub

sub trimHistory()
    while m.history.Count() > 30
        m.history.Shift()
    end while
    ' solo las ultimas 6 paginas se guardan completas; las demas se vuelven a descargar
    last = m.history.Count() - 7
    for i = 0 to last
        m.history[i].content = invalid
    end for
end sub

sub showCurrent(index as integer)
    m.title.text = m.current.title
    if Left(m.current.url, 4) = "app:"
        m.urlLabel.text = ""
    else
        m.urlLabel.text = m.current.url
    end if

    m.list.content = m.current.content
    count = m.current.content.getChildCount()
    if index > 0 and index < count then m.list.jumpToItem = index
    if m.dialog = invalid then m.list.setFocus(true)
end sub

function focusedIndex() as integer
    i = m.list.itemFocused
    if i < 0 then i = 0
    return i
end function

function goBack() as boolean
    if m.loading
        cancelTask()
        return true
    end if
    if m.history.Count() = 0 then return false   ' sin historial: Back cierra la app

    entry = m.history.Pop()
    if entry.content <> invalid
        m.current = entry
        showCurrent(entry.index)
    else
        m.current = invalid
        navigate(entry.url, false, entry.index)
    end if
    return true
end function

sub reload()
    if m.current = invalid then return
    navigate(m.current.url, false, focusedIndex())
end sub

sub onItemSelected()
    if m.loading or m.current = invalid then return
    item = m.current.content.getChild(m.list.itemSelected)
    if item = invalid then return
    if item.url <> "" then navigate(item.url, true)
end sub

' dir > 0: siguiente enlace; dir < 0: enlace anterior
sub jumpLink(dir as integer)
    if m.current = invalid then return
    links = m.current.links
    if links = invalid or links.Count() = 0 then return

    cur = focusedIndex()
    target = -1
    if dir > 0
        for each i in links
            if i > cur
                target = i
                exit for
            end if
        end for
    else
        for k = links.Count() - 1 to 0 step -1
            if links[k] < cur
                target = links[k]
                exit for
            end if
        end for
    end if
    if target >= 0 then m.list.jumpToItem = target
end sub

sub jumpPage(dir as integer)
    if m.current = invalid then return
    count = m.current.content.getChildCount()
    if count = 0 then return
    target = focusedIndex() + dir * 15
    if target < 0 then target = 0
    if target > count - 1 then target = count - 1
    m.list.jumpToItem = target
end sub

' ------------------------------------------------------------------ dialogos

sub openDialog(d as object)
    d.observeField("wasClosed", "onDialogClosed")
    m.dialog = d          ' antes de asignarlo: si reemplaza a otro, el anterior se cierra
    m.top.dialog = d
end sub

sub closeDialog()
    if m.dialog <> invalid then m.dialog.close = true
end sub

sub onDialogClosed(event as object)
    d = event.getRoSGNode()
    if m.dialog <> invalid and d.isSameNode(m.dialog)
        m.dialog = invalid
        m.list.setFocus(true)
    end if
end sub

sub showKeyboard()
    d = CreateObject("roSGNode", "StandardKeyboardDialog")
    d.title = "Ir a una dirección o buscar"
    d.message = ["Escribe una dirección (ejemplo: es.wikipedia.org) o palabras para buscar en la web."]
    d.buttons = ["Ir", "Cancelar"]
    d.observeField("buttonSelected", "onKeyboardButton")
    openDialog(d)
end sub

sub onKeyboardButton(event as object)
    d = event.getRoSGNode()
    index = event.getData()
    text = d.text
    closeDialog()
    if index = 0 and text <> invalid
        text = text.Trim()
        if text <> "" then navigate(text, true)
    end if
end sub

sub showMenu()
    d = CreateObject("roSGNode", "StandardMessageDialog")
    d.title = "Menú"
    if m.showInline
        inlineLabel = "Ocultar enlaces dentro de párrafos"
    else
        inlineLabel = "Mostrar enlaces dentro de párrafos"
    end if
    d.buttons = ["Ir a dirección o buscar", "Inicio", "Recargar página", "Guardar o quitar favorito", inlineLabel, "Cerrar menú"]
    d.observeField("buttonSelected", "onMenuButton")
    openDialog(d)
end sub

sub onMenuButton(event as object)
    index = event.getData()
    if index = 0
        showKeyboard()   ' reemplaza al menu
        return
    end if

    closeDialog()
    if index = 1
        navigate("app:home", true)
    else if index = 2
        reload()
    else if index = 3
        toggleBookmark()
    else if index = 4
        m.showInline = not m.showInline
        reload()
    end if
end sub

' ----------------------------------------------------------------- favoritos

sub toggleBookmark()
    if m.current = invalid or Left(m.current.url, 4) = "app:"
        toast("Abre primero una página web")
        return
    end if
    t = CreateObject("roSGNode", "BrowserTask")
    t.action = "bookmark"
    t.input = m.current.url
    t.pageTitle = m.current.title
    t.observeField("result", "onBookmarkDone")
    m.bmTask = t
    t.control = "RUN"
end sub

sub onBookmarkDone(event as object)
    res = event.getData()
    m.bmTask = invalid
    if res <> invalid and res.message <> invalid then toast(res.message)
end sub

sub toast(text as string)
    m.status.text = text
    m.statusTimer.control = "stop"
    m.statusTimer.control = "start"
end sub

sub onStatusTimer()
    m.status.text = ""
end sub

' ------------------------------------------------------------ control remoto

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.dialog <> invalid then return false

    if key = "back"
        return goBack()
    else if key = "options"
        showMenu()
        return true
    else if key = "play"
        showKeyboard()
        return true
    else if key = "right"
        jumpLink(1)
        return true
    else if key = "left"
        jumpLink(-1)
        return true
    else if key = "fastforward"
        jumpPage(1)
        return true
    else if key = "rewind"
        jumpPage(-1)
        return true
    else if key = "replay"
        reload()
        return true
    end if
    return false
end function
