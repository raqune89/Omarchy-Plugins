import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  // Plugin Lifecycle & Host Integration
  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool closingFromHost: false

  // Paths & State Storage
  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/nodo-pad"
  readonly property string notesPath: stateDir + "/notes.html"
  readonly property string todosPath: stateDir + "/todos.json"

  // Active Tab: 0 = Notes, 1 = Todo List
  property int activeTab: 0

  // Theme Colors
  readonly property color bgColor: Commons.Color.background
  readonly property color fgColor: Commons.Color.foreground
  readonly property color accentColor: Commons.Color.accent
  readonly property color mutedColor: Commons.Color.muted
  readonly property color urgentColor: Commons.Color.urgent
  readonly property color cardBg: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.04)
  readonly property color borderCol: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.12)

  // Status message
  property string statusMessage: "Ready"

  // Active Formatting state for toolbar highlight
  property var activeFormats: ({
    bold: false,
    italic: false,
    underline: false,
    h1: false,
    h2: false,
    h3: false,
    list: false,
    quote: false,
    code: false
  })

  // Per-line block type state & pending inline typing state
  property var lineBlockMap: ({})
  property var pendingInline: ({
    bold: false,
    italic: false,
    underline: false
  })
  property bool hasPendingInline: false
  property int pendingInlineCursorPos: -1
  property bool internalFormattingUpdate: false
  property int lastDocLength: 0
  property int lastParagraphCount: 1
  property var visualDecorations: []

  // Todo Data Models
  property var activeTasks: []
  property var completedTasks: []

  // Notes loaded flag
  property bool notesLoaded: false

  Component.onCompleted: {
    initStorage()
  }

  function initStorage() {
    var defaultHtml = "<h1 style=\"margin-top:6px; margin-bottom:4px; margin-left:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:22px; font-weight:700; color:" + root.fgColor + ";\">Welcome to NoDo-pad</span></h1>" +
                      "<p style=\"margin-top:2px; margin-bottom:2px; margin-left:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; color:" + root.fgColor + ";\">Autosaving formattable notes with rich text styling.</span></p>" +
                      "<ul style=\"margin-top:2px; margin-bottom:2px; margin-left:24px; -qt-list-indent:1;\"><li style=\"margin-top:2px; margin-bottom:2px; margin-left:0px; -qt-block-indent:0;\"><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; color:" + root.fgColor + ";\">Use </span><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:700; color:" + root.fgColor + ";\">Bold</span><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; color:" + root.fgColor + ";\">, </span><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; font-style:italic; color:" + root.fgColor + ";\">Italic</span><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; color:" + root.fgColor + ";\">, or </span><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; text-decoration: underline; color:" + root.fgColor + ";\">Underline</span></li></ul>" +
                      "<p style=\"margin-top:2px; margin-bottom:2px; margin-left:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\"font-family:'JetBrainsMono Nerd Font'; font-size:13px; font-weight:400; color:" + root.fgColor + ";\">All changes autosave continuously.</span></p>"
    Util.execArgv(["sh", "-c", "mkdir -p '" + root.stateDir + "'; [ -f '" + root.notesPath + "' ] || printf '%s' '" + defaultHtml.replace(/'/g, "'\\''") + "' > '" + root.notesPath + "'; [ -f '" + root.todosPath + "' ] || printf '{\\n  \"active\": [],\\n  \"completed\": []\\n}\\n' > '" + root.todosPath + "'"])
    reloadStorageTimer.restart()
  }

  Timer {
    id: reloadStorageTimer
    interval: 150
    repeat: false
    onTriggered: {
      notesFile.reload()
      todosFile.reload()
    }
  }

  // Host summon/hide API
  function open(payloadJson) {
    closingFromHost = false
    root.opened = true
    window.visible = true
  }

  function close() {
    closingFromHost = true
    root.opened = false
    window.visible = false
    closingFromHost = false
  }

  function requestClose() {
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide("raqune.nodo-pad")
    } else {
      root.close()
    }
  }

  function toggle() {
    if (root.opened && window.visible) {
      requestClose()
    } else {
      open("{}")
    }
  }

  function switchTab(arg) {
    root.activeTab = (root.activeTab === 0 ? 1 : 0)
    root.statusMessage = "Switched to " + (root.activeTab === 0 ? "Notepad" : "Todo List")
    Qt.callLater(function() {
      if (root.activeTab === 0 && noteEdit) {
        noteEdit.forceActiveFocus()
      } else if (root.activeTab === 1 && taskInput) {
        taskInput.forceActiveFocus()
      }
    })
    return "tab:" + root.activeTab
  }

  // --- File Storage ---
  FileView {
    id: notesFile
    path: root.notesPath
    watchChanges: false
    printErrors: false
    onLoaded: {
      var raw = text()
      root.internalFormattingUpdate = true
      if (raw && raw.trim().length > 0) {
        noteEdit.text = raw
      } else {
        noteEdit.text = "<h1 style=\"margin-top:6px; margin-bottom:4px; margin-left:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\"font-size:22px; font-weight:600; color:" + root.fgColor + ";\">Welcome to NoDo-pad</span></h1>" +
                        "<p style=\"margin-top:2px; margin-bottom:2px; margin-left:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\"font-size:13px; font-weight:400; color:" + root.fgColor + ";\">Autosaving formattable notes with rich text styling.</span></p>" +
                        "<ul style=\"margin-top:2px; margin-bottom:2px; margin-left:24px; -qt-list-indent:1;\"><li style=\"margin-top:2px; margin-bottom:2px; margin-left:0px; -qt-block-indent:0;\"><span style=\"font-size:13px; color:" + root.fgColor + ";\">Use </span><span style=\"font-size:13px; font-weight:700; color:" + root.fgColor + ";\">Bold</span><span style=\"font-size:13px; color:" + root.fgColor + ";\">, </span><span style=\"font-size:13px; font-style:italic; color:" + root.fgColor + ";\">Italic</span><span style=\"font-size:13px; color:" + root.fgColor + ";\">, or </span><span style=\"font-size:13px; text-decoration: underline; color:" + root.fgColor + ";\">Underline</span></li></ul>"
      }
      root.internalFormattingUpdate = false
      root.notesLoaded = true
      root.syncLineBlockMapFromDocument()
      root.lastDocLength = noteEdit.length
      root.lastParagraphCount = root.getParagraphs().length
      Qt.callLater(function() {
        root.rebuildDocument(noteEdit.cursorPosition, -1, -1, null)
        root.updateActiveFormats()
        root.updateVisualDecorations()
      })
    }
  }

  FileView {
    id: todosFile
    path: root.todosPath
    watchChanges: false
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        root.activeTasks = Array.isArray(parsed.active) ? parsed.active : []
        root.completedTasks = Array.isArray(parsed.completed) ? parsed.completed : []
      } catch(e) {
        root.activeTasks = []
        root.completedTasks = []
      }
    }
  }

  function saveNotes() {
    notesFile.setText(noteEdit.text)
    var d = new Date()
    root.statusMessage = "Notes autosaved at " + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  }

  function saveTodos() {
    var payload = {
      active: root.activeTasks,
      completed: root.completedTasks
    }
    todosFile.setText(JSON.stringify(payload, null, 2) + "\n")
    var d = new Date()
    root.statusMessage = "Todos autosaved at " + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  }

  Timer {
    id: notesAutosaveTimer
    interval: 400
    repeat: false
    onTriggered: root.saveNotes()
  }

  // Todo List operations
  function addTodo(textVal) {
    var trimmed = (textVal || "").trim()
    if (!trimmed) return
    var item = {
      id: Date.now(),
      text: trimmed,
      checked: false,
      created_at: new Date().toISOString()
    }
    var list = root.activeTasks.slice()
    list.unshift(item)
    root.activeTasks = list
    root.saveTodos()
  }

  function toggleTaskCheck(index) {
    if (index < 0 || index >= root.activeTasks.length) return
    var list = root.activeTasks.slice()
    list[index].checked = !list[index].checked
    root.activeTasks = list
    root.saveTodos()
  }

  function removeToCompleted(index) {
    if (index < 0 || index >= root.activeTasks.length) return
    var list = root.activeTasks.slice()
    var item = list.splice(index, 1)[0]
    root.activeTasks = list

    var comp = root.completedTasks.slice()
    comp.unshift({
      id: item.id,
      text: item.text,
      completed_at: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    })
    root.completedTasks = comp
    root.saveTodos()
  }

  function restoreFromCompleted(index) {
    if (index < 0 || index >= root.completedTasks.length) return
    var comp = root.completedTasks.slice()
    var item = comp.splice(index, 1)[0]
    root.completedTasks = comp

    var list = root.activeTasks.slice()
    list.push({
      id: item.id,
      text: item.text,
      checked: false,
      created_at: new Date().toISOString()
    })
    root.activeTasks = list
    root.saveTodos()
  }

  function deletePermanently(index) {
    if (index < 0 || index >= root.completedTasks.length) return
    var comp = root.completedTasks.slice()
    comp.splice(index, 1)
    root.completedTasks = comp
    root.saveTodos()
  }

  function clearAllCompleted() {
    root.completedTasks = []
    root.saveTodos()
  }

  // --- IPC Methods for External Callers / Shortcuts ---
  function addTodoIpc(textVal) {
    root.addTodo(textVal)
    return String(root.activeTasks.length)
  }

  function removeTodoIpc(idx) {
    root.removeToCompleted(parseInt(idx || "0"))
    return String(root.completedTasks.length)
  }

  function restoreTodoIpc(idx) {
    root.restoreFromCompleted(parseInt(idx || "0"))
    return String(root.activeTasks.length)
  }

  function clearCompletedIpc() {
    root.clearAllCompleted()
    return "ok"
  }

  function getTasksCountIpc() {
    return root.activeTasks.length + ":" + root.completedTasks.length
  }

  function applyFormatIpc(type) {
    root.applyFormat(type)
    return "ok"
  }

  function getActiveFormatsIpc() {
    return JSON.stringify(root.activeFormats)
  }

  function getVisualDecosIpc() {
    return JSON.stringify(root.visualDecorations)
  }

  function setCursorPosIpc(posStr) {
    noteEdit.deselect()
    var target = Math.min(noteEdit.length, Math.max(0, parseInt(posStr || "0")))
    noteEdit.cursorPosition = target
    root.updateActiveFormats()
    return String(noteEdit.cursorPosition) + "/" + String(noteEdit.length)
  }

  function insertNewlineIpc() {
    noteEdit.append("<p style=\"-qt-paragraph-type:empty; margin-top:2px; margin-bottom:2px; margin-left:0px;\"><br /></p>")
    noteEdit.cursorPosition = noteEdit.length
    root.updateActiveFormats()
    return String(root.getParagraphs().length)
  }

  function typeTextIpc(txt) {
    var p = noteEdit.cursorPosition
    noteEdit.insert(p, String(txt || ""))
    return String(noteEdit.cursorPosition)
  }

  function getLineStateIpc() {
    var paras = root.getParagraphs()
    var idx = root.getParagraphIndexAt(noteEdit.cursorPosition, paras)
    var p = paras[idx] || { start: 0, end: 0, text: "" }
    var bType = root.getParagraphBlockType(idx, p.start, p.end)
    return JSON.stringify({
      lineIdx: idx,
      blockType: bType,
      text: p.text,
      activeFormats: root.activeFormats
    })
  }

  function escapeHtml(s) {
    if (!s) return ""
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }

  function getParagraphs() {
    if (!noteEdit) return [{ index: 0, start: 0, end: 0, text: "" }]
    var full = noteEdit.getText(0, noteEdit.length)
    var result = []
    var start = 0
    for (var i = 0; i <= full.length; i++) {
      if (i === full.length || full.charCodeAt(i) === 0x2029 || full.charCodeAt(i) === 10) {
        result.push({
          index: result.length,
          start: start,
          end: i,
          text: full.substring(start, i)
        })
        start = i + 1
      }
    }
    if (result.length === 0) {
      result.push({ index: 0, start: 0, end: 0, text: "" })
    }
    return result
  }

  function getParagraphIndexAt(pos, paras) {
    var list = paras || root.getParagraphs()
    for (var i = 0; i < list.length; i++) {
      if (pos >= list[i].start && pos <= list[i].end) {
        return i
      }
    }
    return Math.max(0, list.length - 1)
  }

  function detectBlockFromFragment(frag) {
    if (!frag) return "normal"
    if (frag.indexOf("<hr") !== -1) return "hr"
    if (frag.indexOf("<li") !== -1 || frag.indexOf("<ul") !== -1) return "list"
    if (frag.indexOf("background-color:#050706") !== -1 || frag.indexOf("color:#78b86e") !== -1 || frag.indexOf("<pre") !== -1) return "code"
    if (frag.indexOf("margin-left:24px") !== -1 || frag.indexOf("margin-left: 24px") !== -1 || frag.indexOf("margin-left:14px") !== -1 || frag.indexOf("margin-left:20px") !== -1 || frag.indexOf("blockquote") !== -1 || frag.indexOf("border-left") !== -1) return "quote"
    if (frag.indexOf("<h1") !== -1 || frag.indexOf("font-size:22px") !== -1 || frag.indexOf("font-size:xx-large") !== -1) return "h1"
    if (frag.indexOf("<h2") !== -1 || frag.indexOf("font-size:18px") !== -1 || frag.indexOf("font-size:x-large") !== -1) return "h2"
    if (frag.indexOf("<h3") !== -1 || frag.indexOf("font-size:15px") !== -1 || frag.indexOf("font-size:large") !== -1) return "h3"
    return "normal"
  }

  function syncLineBlockMapFromDocument() {
    var paras = root.getParagraphs()
    var nextMap = {}
    for (var i = 0; i < paras.length; i++) {
      var p = paras[i]
      if (p.end > p.start) {
        var frag = ""
        try {
          frag = noteEdit.getFormattedText(p.start, p.end)
        } catch(e) {}
        nextMap[i] = root.detectBlockFromFragment(frag)
      } else {
        nextMap[i] = root.lineBlockMap[i] || "normal"
      }
    }
    root.lineBlockMap = nextMap
  }

  function getParagraphBlockType(lineIdx, pStart, pEnd) {
    if (root.lineBlockMap && typeof root.lineBlockMap[lineIdx] === "string") {
      return root.lineBlockMap[lineIdx]
    }
    if (pEnd > pStart) {
      var frag = ""
      try {
        frag = noteEdit.getFormattedText(pStart, pEnd)
      } catch(e) {}
      return root.detectBlockFromFragment(frag)
    }
    return "normal"
  }

  function extractParagraphChars(pStart, pEnd, blockType) {
    var plain = noteEdit.getText(pStart, pEnd)
    if (!plain || plain.length === 0) return []

    var frag = ""
    try {
      frag = noteEdit.getFormattedText(pStart, pEnd)
    } catch(e) {}

    var sfIdx = frag.indexOf("<!--StartFragment-->")
    var efIdx = frag.indexOf("<!--EndFragment-->")
    var body = (sfIdx !== -1 && efIdx !== -1 && efIdx > sfIdx)
      ? frag.substring(sfIdx + 20, efIdx)
      : frag

    var chars = []
    var charIdx = 0
    var inB = 0
    var inI = 0
    var inU = 0
    var spanBold = false
    var spanItalic = false
    var spanUnderline = false

    var i = 0
    while (i < body.length && charIdx < plain.length) {
      if (body[i] === "<") {
        var closeIdx = body.indexOf(">", i)
        if (closeIdx === -1) break
        var tagContent = body.substring(i + 1, closeIdx).trim()
        var isClosing = tagContent.indexOf("/") === 0
        var cleanTag = isClosing ? tagContent.substring(1).trim() : tagContent
        var spaceIdx = cleanTag.search(/[\s\/]/)
        var tagName = (spaceIdx === -1 ? cleanTag : cleanTag.substring(0, spaceIdx)).toLowerCase()

        if (tagName === "b" || tagName === "strong") {
          inB = isClosing ? Math.max(0, inB - 1) : (inB + 1)
        } else if (tagName === "i" || tagName === "em") {
          inI = isClosing ? Math.max(0, inI - 1) : (inI + 1)
        } else if (tagName === "u") {
          inU = isClosing ? Math.max(0, inU - 1) : (inU + 1)
        } else if (tagName === "span") {
          if (isClosing) {
            spanBold = false
            spanItalic = false
            spanUnderline = false
          } else {
            var styleMatch = cleanTag.match(/style\s*=\s*"([^"]*)"/i)
            var styleStr = styleMatch ? styleMatch[1].toLowerCase() : ""
            if (blockType === "h1" || blockType === "h2" || blockType === "h3") {
              spanBold = (styleStr.indexOf("word-spacing:0.1px") !== -1 || styleStr.indexOf("word-spacing: 0.1px") !== -1)
            } else {
              spanBold = (styleStr.indexOf("font-weight:700") !== -1 || styleStr.indexOf("font-weight: 700") !== -1 || styleStr.indexOf("font-weight:bold") !== -1)
            }
            if (blockType === "quote") {
              spanItalic = (styleStr.indexOf("letter-spacing:0.1px") !== -1 || styleStr.indexOf("letter-spacing: 0.1px") !== -1)
            } else {
              spanItalic = (styleStr.indexOf("font-style:italic") !== -1 || styleStr.indexOf("font-style: italic") !== -1)
            }
            spanUnderline = (styleStr.indexOf("text-decoration: underline") !== -1 || styleStr.indexOf("text-decoration:underline") !== -1)
          }
        }
        i = closeIdx + 1
      } else if (body[i] === "&") {
        var semiIdx = body.indexOf(";", i)
        if (semiIdx !== -1 && semiIdx - i <= 10) {
          i = semiIdx + 1
        } else {
          i++
        }
        chars.push({
          ch: plain[charIdx],
          bold: (inB > 0 || spanBold),
          italic: (inI > 0 || spanItalic),
          underline: (inU > 0 || spanUnderline)
        })
        charIdx++
      } else {
        var code = body.charCodeAt(i)
        if (code === 10 || code === 13) {
          i++
          continue
        }
        chars.push({
          ch: plain[charIdx],
          bold: (inB > 0 || spanBold),
          italic: (inI > 0 || spanItalic),
          underline: (inU > 0 || spanUnderline)
        })
        charIdx++
        i++
      }
    }

    while (charIdx < plain.length) {
      chars.push({
        ch: plain[charIdx],
        bold: false,
        italic: false,
        underline: false
      })
      charIdx++
    }

    return chars
  }

  function buildSpanHtml(blockType, textStr, isBold, isItalic, isUnderline) {
    var fontSize = "13px"
    if (blockType === "h1") fontSize = "22px"
    else if (blockType === "h2") fontSize = "18px"
    else if (blockType === "h3") fontSize = "15px"
    else if (blockType === "code") fontSize = "12px"

    var isHeading = (blockType === "h1" || blockType === "h2" || blockType === "h3")
    var fontWeight = (isBold || isHeading) ? "700" : "400"
    var extraBoldMarker = (isHeading && isBold) ? "word-spacing:0.1px;" : ""
    var fontStyle = (blockType === "quote" || isItalic) ? "italic" : "normal"
    var extraItalicMarker = (blockType === "quote" && isItalic) ? "letter-spacing:0.1px;" : ""
    var textDeco = isUnderline ? "text-decoration: underline;" : ""
    var textColor = blockType === "quote" ? String(root.accentColor) : (blockType === "code" ? "#78b86e" : String(root.fgColor))
    var bgStyle = blockType === "code" ? "background-color:#050706;" : ""
    var fontFam = blockType === "code" ? "font-family:'JetBrainsMono Nerd Font','monospace';" : "font-family:'JetBrainsMono Nerd Font';"

    return "<span style=\"" + fontFam + "font-size:" + fontSize + ";font-weight:" + fontWeight + ";" + extraBoldMarker + "font-style:" + fontStyle + ";" + extraItalicMarker + textDeco + "color:" + textColor + ";" + bgStyle + "\">" + root.escapeHtml(textStr) + "</span>"
  }

  function buildParagraphHtml(blockType, chars) {
    if (blockType === "hr") {
      return "<hr />"
    }

    var inner = ""
    if (!chars || chars.length === 0) {
      inner = "<br />"
    } else {
      var runText = chars[0].ch
      var rBold = chars[0].bold
      var rItalic = chars[0].italic
      var rUnder = chars[0].underline
      for (var i = 1; i < chars.length; i++) {
        if (chars[i].bold === rBold && chars[i].italic === rItalic && chars[i].underline === rUnder) {
          runText += chars[i].ch
        } else {
          inner += root.buildSpanHtml(blockType, runText, rBold, rItalic, rUnder)
          runText = chars[i].ch
          rBold = chars[i].bold
          rItalic = chars[i].italic
          rUnder = chars[i].underline
        }
      }
      inner += root.buildSpanHtml(blockType, runText, rBold, rItalic, rUnder)
    }

    var isEmpty = (!chars || chars.length === 0)
    var emptyProp = isEmpty ? "-qt-paragraph-type:empty; " : ""

    // Strict Indentation Rule: ONLY list, quote, and code are indented (24px).
    // Normal text and Headers (H1, H2, H3) have 0px indent.
    if (blockType === "h1") {
      return "<h1 style=\"" + emptyProp + "margin-top:6px; margin-bottom:4px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" + inner + "</h1>"
    } else if (blockType === "h2") {
      return "<h2 style=\"" + emptyProp + "margin-top:5px; margin-bottom:3px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" + inner + "</h2>"
    } else if (blockType === "h3") {
      return "<h3 style=\"" + emptyProp + "margin-top:4px; margin-bottom:2px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" + inner + "</h3>"
    } else if (blockType === "list") {
      return "<ul style=\"margin-top:2px; margin-bottom:2px; margin-left:24px; -qt-list-indent:1;\"><li style=\"" + emptyProp + "margin-top:2px; margin-bottom:2px; margin-left:0px; -qt-block-indent:0;\">" + inner + "</li></ul>"
    } else if (blockType === "quote") {
      return "<p style=\"" + emptyProp + "margin-top:4px; margin-bottom:4px; margin-left:24px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" + inner + "</p>"
    } else if (blockType === "code") {
      return "<p style=\"" + emptyProp + "margin-top:4px; margin-bottom:4px; margin-left:24px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" + inner + "</p>"
    } else {
      return "<p style=\"" + emptyProp + "margin-top:2px; margin-bottom:2px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" + inner + "</p>"
    }
  }

  function rebuildDocument(restoreCursorPos, restoreSelStart, restoreSelEnd, inlineMutation) {
    if (!noteEdit) return
    var paras = root.getParagraphs()
    var htmlParts = []

    for (var i = 0; i < paras.length; i++) {
      var p = paras[i]
      var bType = root.getParagraphBlockType(i, p.start, p.end)
      var oldType = (inlineMutation && inlineMutation.oldBlockMap && inlineMutation.oldBlockMap[i]) ? inlineMutation.oldBlockMap[i] : bType
      var chars = root.extractParagraphChars(p.start, p.end, oldType)

      if (inlineMutation) {
        for (var k = 0; k < chars.length; k++) {
          var globalPos = p.start + k
          if (globalPos >= inlineMutation.rangeStart && globalPos < inlineMutation.rangeEnd) {
            if (inlineMutation.type === "clear") {
              chars[k].bold = false
              chars[k].italic = false
              chars[k].underline = false
            } else if (inlineMutation.type === "inline") {
              chars[k][inlineMutation.prop] = inlineMutation.value
            } else if (inlineMutation.type === "inlineAll") {
              chars[k].bold = !!inlineMutation.bold
              chars[k].italic = !!inlineMutation.italic
              chars[k].underline = !!inlineMutation.underline
            }
          }
        }
      }

      htmlParts.push(root.buildParagraphHtml(bType, chars))
    }

    root.internalFormattingUpdate = true
    noteEdit.text = "<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /></head><body>" + htmlParts.join("") + "</body></html>"
    if (restoreSelStart >= 0 && restoreSelEnd > restoreSelStart) {
      noteEdit.select( Math.min(restoreSelStart, noteEdit.length), Math.min(restoreSelEnd, noteEdit.length) )
    } else if (restoreCursorPos >= 0) {
      noteEdit.cursorPosition = Math.min(restoreCursorPos, noteEdit.length)
    }
    root.lastDocLength = noteEdit.length
    root.lastParagraphCount = paras.length
    root.internalFormattingUpdate = false
    root.updateVisualDecorations()
  }

  function updateVisualDecorations() {
    if (!noteEdit || !root.notesLoaded) return
    var paras = root.getParagraphs()
    var decos = []
    var i = 0
    while (i < paras.length) {
      var bType = root.getParagraphBlockType(i, paras[i].start, paras[i].end)
      if (bType === "quote" || bType === "code") {
        var groupStart = paras[i].start
        var groupEnd = paras[i].end
        var j = i + 1
        while (j < paras.length && root.getParagraphBlockType(j, paras[j].start, paras[j].end) === bType) {
          groupEnd = paras[j].end
          j++
        }
        try {
          var rStart = noteEdit.positionToRectangle(groupStart)
          var rEnd = noteEdit.positionToRectangle(groupEnd)
          var topY = rStart.y
          var botY = Math.max(topY + 18, rEnd.y + rEnd.height)
          decos.push({
            kind: bType,
            y: topY,
            height: botY - topY
          })
        } catch(e) {}
        i = j
      } else {
        i++
      }
    }
    root.visualDecorations = decos
  }

  function updateActiveFormats() {
    if (!noteEdit || !root.notesLoaded || root.internalFormattingUpdate) return
    var start = noteEdit.selectionStart
    var end = noteEdit.selectionEnd
    var hasSelection = (start !== end && start >= 0 && end > start)
    var pos = noteEdit.cursorPosition

    var paras = root.getParagraphs()
    var lineIdx = root.getParagraphIndexAt(pos, paras)
    var curPara = paras[lineIdx] || { start: 0, end: 0, text: "" }
    var bType = root.getParagraphBlockType(lineIdx, curPara.start, curPara.end)

    var isBold = false
    var isItalic = false
    var isUnder = false

    if (!hasSelection && root.hasPendingInline && pos === root.pendingInlineCursorPos) {
      isBold = !!root.pendingInline.bold
      isItalic = !!root.pendingInline.italic
      isUnder = !!root.pendingInline.underline
    } else if (curPara.end > curPara.start) {
      var chars = root.extractParagraphChars(curPara.start, curPara.end, bType)
      if (hasSelection) {
        var sLocal = Math.max(0, start - curPara.start)
        var eLocal = Math.min(chars.length, end - curPara.start)
        if (eLocal > sLocal) {
          isBold = true
          isItalic = true
          isUnder = true
          for (var k = sLocal; k < eLocal; k++) {
            if (!chars[k].bold) isBold = false
            if (!chars[k].italic) isItalic = false
            if (!chars[k].underline) isUnder = false
          }
        }
      } else {
        var localIdx = Math.max(0, Math.min(chars.length - 1, pos - curPara.start - 1))
        if (pos === curPara.start && chars.length > 0) localIdx = 0
        if (chars[localIdx]) {
          isBold = !!chars[localIdx].bold
          isItalic = !!chars[localIdx].italic
          isUnder = !!chars[localIdx].underline
        }
      }
    }

    root.activeFormats = {
      bold: isBold,
      italic: isItalic,
      underline: isUnder,
      h1: bType === "h1",
      h2: bType === "h2",
      h3: bType === "h3",
      list: bType === "list",
      quote: bType === "quote",
      code: bType === "code"
    }
    root.updateVisualDecorations()
  }

  function handleNoteTextEdited() {
    if (!noteEdit || !root.notesLoaded || root.internalFormattingUpdate) return

    var paras = root.getParagraphs()
    var pos = noteEdit.cursorPosition
    var curLineIdx = root.getParagraphIndexAt(pos, paras)
    var newLen = noteEdit.length
    var deltaLen = newLen - root.lastDocLength
    var deltaParas = paras.length - root.lastParagraphCount

    // 1. Handle paragraph splits (Enter) or merges (Backspace)
    if (deltaParas > 0) {
      var nextMap = {}
      var prevLineIdx = Math.max(0, curLineIdx - 1)
      var prevType = root.lineBlockMap[prevLineIdx] || "normal"
      var exitedEmptyBlock = false

      if ((prevType === "list" || prevType === "quote" || prevType === "code") &&
          paras[prevLineIdx] && paras[prevLineIdx].text.trim().length === 0 &&
          paras[curLineIdx] && paras[curLineIdx].text.trim().length === 0) {
        // Pressing Enter on an empty list/quote/code item exits the block back to normal text
        exitedEmptyBlock = true
      }

      for (var i = 0; i < paras.length; i++) {
        if (i < curLineIdx) {
          nextMap[i] = root.lineBlockMap[i] || "normal"
        } else if (i === curLineIdx) {
          if (exitedEmptyBlock) {
            nextMap[prevLineIdx] = "normal"
            nextMap[i] = "normal"
          } else if (prevType === "list" || prevType === "quote" || prevType === "code") {
            nextMap[i] = prevType
          } else {
            nextMap[i] = "normal"
          }
        } else {
          nextMap[i] = root.lineBlockMap[i - deltaParas] || "normal"
        }
      }
      root.lineBlockMap = nextMap
      root.rebuildDocument(pos, -1, -1, null)
      root.updateActiveFormats()
      notesAutosaveTimer.restart()
      return
    } else if (deltaParas < 0) {
      var mergedMap = {}
      for (var m = 0; m < paras.length; m++) {
        if (m <= curLineIdx) {
          mergedMap[m] = root.lineBlockMap[m] || "normal"
        } else {
          mergedMap[m] = root.lineBlockMap[m - deltaParas] || "normal"
        }
      }
      root.lineBlockMap = mergedMap
    }

    // 2. If characters were typed while pendingInline is active or on a newly formatted line
    var curPara = paras[curLineIdx]
    var curBlockType = root.lineBlockMap[curLineIdx] || "normal"
    if (deltaLen > 0 && pos >= deltaLen) {
      var insertStart = pos - deltaLen
      var needRebuild = false
      var mutation = null

      if (root.hasPendingInline) {
        needRebuild = true
        mutation = {
          type: "inlineAll",
          bold: root.pendingInline.bold,
          italic: root.pendingInline.italic,
          underline: root.pendingInline.underline,
          rangeStart: insertStart,
          rangeEnd: pos
        }
        root.pendingInlineCursorPos = pos
      } else if (curPara && curPara.end - curPara.start === deltaLen && curBlockType !== "normal") {
        // First character(s) typed on an empty block-formatted line
        needRebuild = true
      }

      if (needRebuild) {
        root.rebuildDocument(pos, -1, -1, mutation)
        root.updateActiveFormats()
        notesAutosaveTimer.restart()
        return
      }
    }

    root.lastDocLength = newLen
    root.lastParagraphCount = paras.length
    notesAutosaveTimer.restart()
    root.updateActiveFormats()
  }

  // Formatting operations for Notepad
  function applyFormat(type) {
    if (!noteEdit) return
    var start = noteEdit.selectionStart
    var end = noteEdit.selectionEnd
    var hasSelection = (start !== end && start >= 0 && end > start)
    var pos = noteEdit.cursorPosition
    var paras = root.getParagraphs()
    var curLineIdx = root.getParagraphIndexAt(pos, paras)
    var curPara = paras[curLineIdx] || { index: 0, start: 0, end: 0, text: "" }

    var isBlock = (type === "h1" || type === "h2" || type === "h3" || type === "list" || type === "quote" || type === "code")
    var isInline = (type === "bold" || type === "italic" || type === "underline")

    if (isBlock) {
      var isCurrentlyActive = !!root.activeFormats[type]
      var targetBlock = isCurrentlyActive ? "normal" : type

      var startLine = hasSelection ? root.getParagraphIndexAt(start, paras) : curLineIdx
      var endLine = hasSelection ? root.getParagraphIndexAt(Math.max(start, end - 1), paras) : curLineIdx

      var oldMap = {}
      var nextMap = {}
      for (var i = 0; i < paras.length; i++) {
        var existing = root.getParagraphBlockType(i, paras[i].start, paras[i].end)
        oldMap[i] = existing
        if (i >= startLine && i <= endLine) {
          nextMap[i] = targetBlock
        } else {
          nextMap[i] = existing
        }
      }
      root.lineBlockMap = nextMap
      root.rebuildDocument(pos, hasSelection ? start : -1, hasSelection ? end : -1, {
        type: "none",
        rangeStart: -1,
        rangeEnd: -1,
        oldBlockMap: oldMap
      })
      noteEdit.forceActiveFocus()
      notesAutosaveTimer.restart()
      root.updateActiveFormats()
      return
    }

    if (isInline) {
      var targetState = !root.activeFormats[type]

      if (hasSelection) {
        root.pendingInline = {
          bold: type === "bold" ? targetState : root.activeFormats.bold,
          italic: type === "italic" ? targetState : root.activeFormats.italic,
          underline: type === "underline" ? targetState : root.activeFormats.underline
        }
        root.hasPendingInline = false
        root.rebuildDocument(pos, start, end, {
          type: "inline",
          prop: type,
          value: targetState,
          rangeStart: start,
          rangeEnd: end
        })
      } else {
        // No selection: update pending typing format AND if cursor touches existing non-space text on the line, toggle that run/line too
        root.pendingInline = {
          bold: type === "bold" ? targetState : root.activeFormats.bold,
          italic: type === "italic" ? targetState : root.activeFormats.italic,
          underline: type === "underline" ? targetState : root.activeFormats.underline
        }
        root.hasPendingInline = true
        root.pendingInlineCursorPos = pos

        var prevChar = (pos > curPara.start) ? noteEdit.getText(pos - 1, pos) : ""
        var nextChar = (pos < curPara.end) ? noteEdit.getText(pos, pos + 1) : ""
        var touchingWord = (curPara.end > curPara.start) && (prevChar !== " " && prevChar !== "\t") && (prevChar !== "" || nextChar !== "")

        if (touchingWord) {
          var bType = root.getParagraphBlockType(curLineIdx, curPara.start, curPara.end)
          var chars = root.extractParagraphChars(curPara.start, curPara.end, bType)
          var rStart = curPara.start
          var rEnd = curPara.end

          if (!targetState && chars.length > 0) {
            // Find contiguous run around cursor that currently has this inline format active
            var pivot = Math.max(0, Math.min(chars.length - 1, pos - curPara.start - 1))
            if (pos === curPara.start) pivot = 0
            if (chars[pivot] && chars[pivot][type]) {
              var sIdx = pivot
              while (sIdx > 0 && chars[sIdx - 1][type]) sIdx--
              var eIdx = pivot + 1
              while (eIdx < chars.length && chars[eIdx][type]) eIdx++
              rStart = curPara.start + sIdx
              rEnd = curPara.start + eIdx
            }
          }

          root.rebuildDocument(pos, -1, -1, {
            type: "inline",
            prop: type,
            value: targetState,
            rangeStart: rStart,
            rangeEnd: rEnd
          })
          root.pendingInlineCursorPos = noteEdit.cursorPosition
        }
      }

      noteEdit.forceActiveFocus()
      notesAutosaveTimer.restart()
      root.updateActiveFormats()
      return
    }

    if (type === "clear") {
      var cStartLine = hasSelection ? root.getParagraphIndexAt(start, paras) : curLineIdx
      var cEndLine = hasSelection ? root.getParagraphIndexAt(Math.max(start, end - 1), paras) : curLineIdx
      var cOldMap = {}
      var cNextMap = {}
      for (var c = 0; c < paras.length; c++) {
        var ex = root.getParagraphBlockType(c, paras[c].start, paras[c].end)
        cOldMap[c] = ex
        cNextMap[c] = (c >= cStartLine && c <= cEndLine) ? "normal" : ex
      }
      root.lineBlockMap = cNextMap
      root.pendingInline = { bold: false, italic: false, underline: false }
      root.hasPendingInline = true
      root.pendingInlineCursorPos = pos

      var clearFrom = hasSelection ? start : curPara.start
      var clearTo = hasSelection ? end : curPara.end
      root.rebuildDocument(pos, hasSelection ? start : -1, hasSelection ? end : -1, {
        type: "clear",
        rangeStart: clearFrom,
        rangeEnd: clearTo,
        oldBlockMap: cOldMap
      })
      noteEdit.forceActiveFocus()
      notesAutosaveTimer.restart()
      root.updateActiveFormats()
      return
    }

    if (type === "hr") {
      noteEdit.insert(pos, "<hr />")
      root.syncLineBlockMapFromDocument()
      noteEdit.forceActiveFocus()
      notesAutosaveTimer.restart()
      Qt.callLater(function() { root.updateActiveFormats() })
      return
    }
  }

  // --- Floating Window ---
  FloatingWindow {
    id: window
    title: "NoDo-pad"
    color: root.bgColor
    implicitWidth: 680
    implicitHeight: 600
    minimumSize: Qt.size(480, 420)
    visible: false

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function") {
        root.shell.hide("raqune.nodo-pad")
      }
    }

    // Keyboard Shortcuts inside window
    Shortcut {
      sequence: "Meta+Alt+N"
      onActivated: root.switchTab("shortcut")
    }

    Shortcut {
      sequence: "Escape"
      onActivated: root.requestClose()
    }

    Shortcut {
      sequence: StandardKey.Bold
      onActivated: root.applyFormat("bold")
    }

    Shortcut {
      sequence: StandardKey.Italic
      onActivated: root.applyFormat("italic")
    }

    Shortcut {
      sequence: StandardKey.Underline
      onActivated: root.applyFormat("underline")
    }

    // Main Container
    Rectangle {
      anchors.fill: parent
      color: root.bgColor
      border.color: root.borderCol
      border.width: 1

      Column {
        anchors.fill: parent
        spacing: 0

        // ================= HEADER & DRAG BAR =================
        Rectangle {
          id: headerBar
          width: parent.width
          height: 44
          color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.05)
          border.color: root.borderCol
          border.width: 1

          // Drag gesture across the whole header bar
          MouseArea {
            id: dragArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: function(mouse) {
              window.startSystemMove()
            }
          }

          Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            // App Icon & Title
            Row {
              id: titleGroup
              width: 120
              height: parent.height
              spacing: 8

              Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                source: Qt.resolvedUrl("nodo-pad-cad.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 92
                text: "NoDo-pad"
                font.family: Style.font.family
                font.pixelSize: 14
                font.bold: true
                color: root.fgColor
                elide: Text.ElideRight
                clip: true
              }
            }

            // Tab Buttons in Header
            Row {
              id: tabButtonGroup
              width: parent.width - titleGroup.width - 24
              height: parent.height
              spacing: 8

              // Tab 1 Button: Notepad
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 100
                height: 28
                radius: 4
                color: root.activeTab === 0 ? root.accentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.08)
                border.color: root.activeTab === 0 ? root.accentColor : root.borderCol
                border.width: 1

                Row {
                  anchors.centerIn: parent
                  spacing: 4
                  Text {
                    text: "📝"
                    font.pixelSize: 12
                  }
                  Text {
                    text: "Notes"
                    font.family: Style.font.family
                    font.pixelSize: 12
                    font.bold: root.activeTab === 0
                    color: root.activeTab === 0 ? root.bgColor : root.fgColor
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { root.activeTab = 0 }
                }
              }

              // Tab 2 Button: Todo List
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                height: 28
                radius: 4
                color: root.activeTab === 1 ? root.accentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.08)
                border.color: root.activeTab === 1 ? root.accentColor : root.borderCol
                border.width: 1

                Row {
                  anchors.centerIn: parent
                  spacing: 4
                  Text {
                    text: "✓"
                    font.pixelSize: 12
                    color: root.activeTab === 1 ? root.bgColor : root.accentColor
                    font.bold: true
                  }
                  Text {
                    text: "Tasks (" + root.activeTasks.length + ")"
                    font.family: Style.font.family
                    font.pixelSize: 12
                    font.bold: root.activeTab === 1
                    color: root.activeTab === 1 ? root.bgColor : root.fgColor
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { root.activeTab = 1 }
                }
              }
            }
          }
        }

        // ================= TAB 1: NOTEPAD =================
        Item {
          id: tabNotes
          width: parent.width
          height: parent.height - headerBar.height - footerBar.height
          visible: root.activeTab === 0

          Column {
            anchors.fill: parent
            spacing: 0

            // Formatting Toolbar
            Rectangle {
              id: toolbar
              width: parent.width
              height: 38
              color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.03)
              border.color: root.borderCol
              border.width: 1

              Flickable {
                anchors.fill: parent
                contentWidth: toolbarRow.implicitWidth + 24
                contentHeight: parent.height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row {
                  id: toolbarRow
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  spacing: 4

                  // Helper Component for Format Buttons
                  Repeater {
                    model: [
                      { id: "bold", label: "B", tip: "Bold", bold: true, width: 28 },
                      { id: "italic", label: "I", tip: "Italic", italic: true, width: 28 },
                      { id: "underline", label: "U", tip: "Underline", underline: true, width: 28 },
                      { id: "h1", label: "H1", tip: "Heading 1", bold: true, width: 34 },
                      { id: "h2", label: "H2", tip: "Heading 2", bold: true, width: 34 },
                      { id: "h3", label: "H3", tip: "Heading 3", bold: true, width: 34 },
                      { id: "list", label: "• List", tip: "Bullet List", width: 56 },
                      { id: "quote", label: "❝ Quote", tip: "Blockquote", width: 68 },
                      { id: "code", label: "</> Code", tip: "Code Snippet", width: 68 },
                      { id: "hr", label: "― Line", tip: "Horizontal Divider", width: 58 },
                      { id: "clear", label: "⌫ Clear", tip: "Clear Format", width: 62 }
                    ]

                    Rectangle {
                      id: fmtBtn
                      width: modelData.width
                      height: 26
                      radius: 3
                      readonly property bool isActive: !!(root.activeFormats && root.activeFormats[modelData.id])
                      color: isActive ? root.accentColor : (fmtBtnHover.containsMouse ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.25) : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.05))
                      border.color: isActive || fmtBtnHover.containsMouse ? root.accentColor : root.borderCol
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Style.font.family
                        font.pixelSize: 11
                        font.bold: modelData.bold || isActive || false
                        font.italic: modelData.italic || false
                        font.underline: modelData.underline || false
                        color: isActive ? root.bgColor : (fmtBtnHover.containsMouse ? root.accentColor : root.fgColor)
                      }

                      MouseArea {
                        id: fmtBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          root.applyFormat(modelData.id)
                        }
                      }
                    }
                  }
                }
              }
            }

            // Note Editor Area
            ScrollView {
              id: noteScrollView
              width: parent.width
              height: parent.height - toolbar.height
              clip: true

              TextEdit {
                id: noteEdit
                width: noteScrollView.width
                height: Math.max(noteScrollView.height, contentHeight + 40)
                textFormat: TextEdit.RichText
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                color: root.fgColor
                selectionColor: root.accentColor
                selectedTextColor: root.bgColor
                font.family: "JetBrainsMono Nerd Font", "monospace"
                font.pixelSize: 13
                leftPadding: 16
                rightPadding: 16
                topPadding: 14
                bottomPadding: 24

                onWidthChanged: Qt.callLater(function() { root.updateVisualDecorations() })
                onContentHeightChanged: Qt.callLater(function() { root.updateVisualDecorations() })

                onCursorPositionChanged: {
                  if (!root.internalFormattingUpdate) {
                    if (root.hasPendingInline && noteEdit.length === root.lastDocLength && noteEdit.cursorPosition !== root.pendingInlineCursorPos) {
                      root.hasPendingInline = false
                    }
                    root.updateActiveFormats()
                  }
                }
                onSelectionStartChanged: {
                  if (!root.internalFormattingUpdate) root.updateActiveFormats()
                }
                onSelectionEndChanged: {
                  if (!root.internalFormattingUpdate) root.updateActiveFormats()
                }

                onTextChanged: {
                  if (root.notesLoaded && !root.internalFormattingUpdate) {
                    root.handleNoteTextEdited()
                  }
                }

                // Visual block decorations for Quote (continuous left vertical bar) and Code (indented darker background box)
                Repeater {
                  model: root.visualDecorations
                  Rectangle {
                    z: -1
                    x: modelData.kind === "quote" ? (noteEdit.leftPadding + 10) : (noteEdit.leftPadding + 16)
                    y: modelData.kind === "quote" ? (modelData.y + 1) : (modelData.y - 2)
                    width: modelData.kind === "quote" ? 3 : Math.max(80, noteEdit.width - noteEdit.leftPadding - noteEdit.rightPadding - 16)
                    height: modelData.kind === "quote" ? Math.max(16, modelData.height - 2) : Math.max(20, modelData.height + 4)
                    radius: modelData.kind === "quote" ? 1.5 : 4
                    color: modelData.kind === "quote" ? root.accentColor : "#050706"
                    border.width: modelData.kind === "code" ? 1 : 0
                    border.color: modelData.kind === "code" ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                  }
                }
              }
            }
          }
        }

        // ================= TAB 2: TODO LIST =================
        Item {
          id: tabTodos
          width: parent.width
          height: parent.height - headerBar.height - footerBar.height
          visible: root.activeTab === 1

          Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Input Row: Add New Task
            Row {
              id: todoInputRow
              width: parent.width
              height: 34
              spacing: 8

              TextField {
                id: taskInput
                width: parent.width - addBtn.width - 8
                height: 34
                placeholderText: "Enter a new task... (press Enter to add)"
                font.family: Style.font.family
                font.pixelSize: 13
                onAccepted: {
                  if (text.trim().length > 0) {
                    root.addTodo(text)
                    text = ""
                  }
                }
              }

              Button {
                id: addBtn
                width: 70
                height: 34
                text: "Add"
                bordered: true
                accent: root.accentColor
                onClicked: {
                  if (taskInput.text.trim().length > 0) {
                    root.addTodo(taskInput.text)
                    taskInput.text = ""
                  }
                }
              }
            }

            // Scrollable Task Lists
            ScrollView {
              id: todoScrollView
              width: parent.width
              height: parent.height - todoInputRow.height - 12
              clip: true

              Column {
                width: todoScrollView.width
                spacing: 14

                // --- ACTIVE TASKS SECTION ---
                Column {
                  width: parent.width
                  spacing: 6

                  Row {
                    width: parent.width
                    Text {
                      text: "ACTIVE TASKS (" + root.activeTasks.length + ")"
                      font.family: Style.font.family
                      font.pixelSize: 11
                      font.bold: true
                      color: root.accentColor
                    }
                  }

                  // Empty active notice
                  Rectangle {
                    width: parent.width
                    height: 48
                    color: root.cardBg
                    radius: 4
                    border.color: root.borderCol
                    border.width: 1
                    visible: root.activeTasks.length === 0

                    Text {
                      anchors.centerIn: parent
                      text: "No active tasks. Add one above!"
                      font.family: Style.font.family
                      font.pixelSize: 12
                      color: root.mutedColor
                    }
                  }

                  // Active Task Items
                  Repeater {
                    model: root.activeTasks

                    Rectangle {
                      id: taskCard
                      width: parent.width
                      height: 40
                      color: root.cardBg
                      radius: 4
                      border.color: modelData.checked ? root.accentColor : root.borderCol
                      border.width: 1

                      Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 10

                        // Checkbox
                        Rectangle {
                          anchors.verticalCenter: parent.verticalCenter
                          width: 20
                          height: 20
                          radius: 3
                          color: modelData.checked ? root.accentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.08)
                          border.color: modelData.checked ? root.accentColor : root.borderCol
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 12
                            font.bold: true
                            color: root.bgColor
                            visible: modelData.checked
                          }

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              root.toggleTaskCheck(index)
                            }
                          }
                        }

                        // Task Text
                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          width: parent.width - 20 - 74 - 20
                          text: modelData.text
                          font.family: Style.font.family
                          font.pixelSize: 13
                          font.strikeout: modelData.checked
                          color: modelData.checked ? root.mutedColor : root.fgColor
                          elide: Text.ElideRight
                          clip: true
                        }

                        // Remove Button (Moves to Completed)
                        Rectangle {
                          anchors.verticalCenter: parent.verticalCenter
                          width: 74
                          height: 24
                          radius: 3
                          color: removeHover.containsMouse ? Qt.rgba(Commons.Color.urgent.r, Commons.Color.urgent.g, Commons.Color.urgent.b, 0.2) : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.06)
                          border.color: removeHover.containsMouse ? root.urgentColor : root.borderCol
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: "Remove"
                            font.family: Style.font.family
                            font.pixelSize: 11
                            color: removeHover.containsMouse ? root.urgentColor : root.fgColor
                          }

                          MouseArea {
                            id: removeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              root.removeToCompleted(index)
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Divider between sections
                Rectangle {
                  width: parent.width
                  height: 1
                  color: root.borderCol
                }

                // --- COMPLETED TASKS SECTION ---
                Column {
                  width: parent.width
                  spacing: 6

                  Row {
                    width: parent.width
                    spacing: 8

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width - clearAllBtn.width - 8
                      text: "COMPLETED (" + root.completedTasks.length + ")"
                      font.family: Style.font.family
                      font.pixelSize: 11
                      font.bold: true
                      color: root.mutedColor
                      elide: Text.ElideRight
                    }

                    Rectangle {
                      id: clearAllBtn
                      anchors.verticalCenter: parent.verticalCenter
                      width: 70
                      height: 22
                      radius: 3
                      visible: root.completedTasks.length > 0
                      color: clearHover.containsMouse ? root.urgentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.06)
                      border.color: root.borderCol
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.family: Style.font.family
                        font.pixelSize: 10
                        color: clearHover.containsMouse ? "#ffffff" : root.fgColor
                      }

                      MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          root.clearAllCompleted()
                        }
                      }
                    }
                  }

                  // Completed Task Items
                  Repeater {
                    model: root.completedTasks

                    Rectangle {
                      width: parent.width
                      height: 38
                      color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.02)
                      radius: 4
                      border.color: root.borderCol
                      border.width: 1

                      Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          text: "✔"
                          font.pixelSize: 11
                          color: root.accentColor
                        }

                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          width: parent.width - 16 - 60 - 28 - 24
                          text: modelData.text + (modelData.completed_at ? "  (" + modelData.completed_at + ")" : "")
                          font.family: Style.font.family
                          font.pixelSize: 12
                          font.strikeout: true
                          color: root.mutedColor
                          elide: Text.ElideRight
                          clip: true
                        }

                        // Restore Button
                        Rectangle {
                          id: restoreBtn
                          anchors.verticalCenter: parent.verticalCenter
                          width: 60
                          height: 22
                          radius: 3
                          color: restoreHover.containsMouse ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.2) : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.05)
                          border.color: restoreHover.containsMouse ? root.accentColor : root.borderCol
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: "↩ Restore"
                            font.family: Style.font.family
                            font.pixelSize: 10
                            color: restoreHover.containsMouse ? root.accentColor : root.fgColor
                          }

                          MouseArea {
                            id: restoreHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              root.restoreFromCompleted(index)
                            }
                          }
                        }

                        // Permanent Delete Button
                        Rectangle {
                          id: delBtn
                          anchors.verticalCenter: parent.verticalCenter
                          width: 24
                          height: 22
                          radius: 3
                          color: delHover.containsMouse ? root.urgentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.05)
                          border.color: root.borderCol
                          border.width: 1

                          Text {
                            anchors.centerIn: parent
                            text: "🗑"
                            font.pixelSize: 11
                            color: delHover.containsMouse ? "#ffffff" : root.fgColor
                          }

                          MouseArea {
                            id: delHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              root.deletePermanently(index)
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ================= FOOTER / STATUS BAR =================
        Rectangle {
          id: footerBar
          width: parent.width
          height: 26
          color: Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.03)
          border.color: root.borderCol
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - 240 - 10
              text: root.statusMessage
              font.family: Style.font.family
              font.pixelSize: 11
              color: root.mutedColor
              elide: Text.ElideRight
              clip: true
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: 240
              horizontalAlignment: Text.AlignRight
              text: "Super+Alt+T: Toggle | Super+Alt+N: Switch Tab | Esc: Dismiss"
              font.family: Style.font.family
              font.pixelSize: 10
              color: root.mutedColor
              elide: Text.ElideRight
              clip: true
            }
          }
        }
      }
    }
  }
}
