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

  // Pin Status
  property bool isPinned: false

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

  // Todo Data Models
  property var activeTasks: []
  property var completedTasks: []

  // Notes loaded flag
  property bool notesLoaded: false

  Component.onCompleted: {
    initStorage()
  }

  function initStorage() {
    Util.execArgv(["sh", "-c", "mkdir -p '" + root.stateDir + "'; [ -f '" + root.notesPath + "' ] || printf '<h1>Welcome to NoDo-pad</h1><p>Autosaving formattable notes with rich text styling.</p><ul><li>Use <b>Bold</b>, <i>Italic</i>, or <u>Underline</u></li><li>Add <b>H1/H2</b> headers, bullet lists, blockquotes, and code snippets</li></ul><hr><p>All changes autosave continuously.</p>' > '" + root.notesPath + "'; [ -f '" + root.todosPath + "' ] || printf '{\\n  \"active\": [],\\n  \"completed\": []\\n}\\n' > '" + root.todosPath + "'"])
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
    checkPinStatus()
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

  function switchTab() {
    root.activeTab = (root.activeTab === 0 ? 1 : 0)
    root.statusMessage = "Switched to " + (root.activeTab === 0 ? "Notepad" : "Todo List")
    return "tab:" + root.activeTab
  }

  function togglePin() {
    Util.execArgv(["sh", "-c", "hyprctl dispatch 'hl.dsp.window.pin()' >/dev/null 2>&1 || hyprctl dispatch pin activewindow >/dev/null 2>&1"])
    pinCheckTimer.restart()
    return "ok"
  }

  function checkPinStatus() {
    pinChecker.running = true
  }

  // Pin state checker process
  Process {
    id: pinChecker
    command: ["sh", "-c", "hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.title == \"NoDo-pad\") | .pinned' 2>/dev/null || echo false"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var str = text.trim()
        root.isPinned = (str === "true" || str === "1")
      }
    }
  }

  Timer {
    id: pinCheckTimer
    interval: 200
    repeat: false
    onTriggered: checkPinStatus()
  }

  // --- File Storage ---
  FileView {
    id: notesFile
    path: root.notesPath
    watchChanges: false
    printErrors: false
    onLoaded: {
      var raw = text()
      if (raw && raw.trim().length > 0) {
        noteEdit.text = raw
      } else {
        noteEdit.text = "<h1>Welcome to NoDo-pad</h1><p>Autosaving formattable notes with rich text styling.</p><ul><li>Use <b>Bold</b>, <i>Italic</i>, or <u>Underline</u></li><li>Add <b>H1/H2</b> headers, bullet lists, blockquotes, and code snippets</li></ul><hr><p>All changes autosave continuously.</p>"
      }
      root.notesLoaded = true
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

  // Formatting operations for Notepad
  function applyFormat(type) {
    var start = noteEdit.selectionStart
    var end = noteEdit.selectionEnd
    var hasSelection = (start !== end && start >= 0 && end > start)
    var sel = hasSelection ? noteEdit.getText(start, end) : ""
    var formatted = ""

    switch (type) {
      case "bold":
        formatted = "<b>" + (sel || "Bold Text") + "</b>"
        break
      case "italic":
        formatted = "<i>" + (sel || "Italic Text") + "</i>"
        break
      case "underline":
        formatted = "<u>" + (sel || "Underlined Text") + "</u>"
        break
      case "h1":
        formatted = "<h1>" + (sel || "Heading 1") + "</h1>"
        break
      case "h2":
        formatted = "<h2>" + (sel || "Heading 2") + "</h2>"
        break
      case "h3":
        formatted = "<h3>" + (sel || "Heading 3") + "</h3>"
        break
      case "list":
        if (hasSelection) {
          var lines = sel.split("\n")
          var items = ""
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim()) items += "<li>" + lines[i] + "</li>"
          }
          formatted = "<ul>" + (items || "<li>" + sel + "</li>") + "</ul>"
        } else {
          formatted = "<ul><li>List item</li></ul>"
        }
        break
      case "quote":
        formatted = "<blockquote style=\"margin: 6px 0 6px 14px; padding-left: 10px; border-left: 2px solid " + root.accentColor + "; color: " + root.mutedColor + ";\">" + (sel || "Quote block") + "</blockquote>"
        break
      case "code":
        formatted = "<pre style=\"background-color: rgba(255,255,255,0.08); padding: 6px 10px; border-radius: 4px; font-family: monospace;\"><code>" + (sel || "code snippet") + "</code></pre>"
        break
      case "hr":
        formatted = "<hr />"
        break
      case "clear":
        formatted = sel
        break
    }

    if (hasSelection) {
      noteEdit.remove(start, end)
      noteEdit.insert(start, formatted)
      noteEdit.select(start, start + formatted.length)
    } else {
      var pos = noteEdit.cursorPosition
      noteEdit.insert(pos, formatted)
      noteEdit.cursorPosition = pos + formatted.length
    }
    noteEdit.forceActiveFocus()
    notesAutosaveTimer.restart()
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
      if (visible) {
        root.checkPinStatus()
      } else if (!root.closingFromHost && root.shell && typeof root.shell.hide === "function") {
        root.shell.hide("raqune.nodo-pad")
      }
    }

    // Keyboard Shortcuts inside window
    Shortcut {
      sequence: "Super+Alt+N"
      onActivated: root.switchTab()
    }

    Shortcut {
      sequence: "Super+Alt+P"
      onActivated: root.togglePin()
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

          // Drag gesture over the header bar
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
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 8

            // App Icon & Title
            Row {
              id: titleGroup
              width: 130
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
                width: 102
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
              width: parent.width - titleGroup.width - windowActionGroup.width - 24
              height: parent.height
              spacing: 6

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

            // Window Actions: Pin & Close
            Row {
              id: windowActionGroup
              width: 64
              height: parent.height
              spacing: 6

              // Pin Toggle Button
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 4
                color: root.isPinned ? root.accentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.06)
                border.color: root.isPinned ? root.accentColor : root.borderCol
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "📌"
                  font.pixelSize: 13
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.togglePin()
                  }
                }
              }

              // Close Button
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 4
                color: closeHover.containsMouse ? root.urgentColor : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.06)
                border.color: root.borderCol
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 13
                  font.bold: true
                  color: closeHover.containsMouse ? "#ffffff" : root.fgColor
                }

                MouseArea {
                  id: closeHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.requestClose()
                  }
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
                      color: fmtBtnHover.containsMouse ? Qt.rgba(Commons.Color.accent.r, Commons.Color.accent.g, Commons.Color.accent.b, 0.2) : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.05)
                      border.color: fmtBtnHover.containsMouse ? root.accentColor : root.borderCol
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Style.font.family
                        font.pixelSize: 11
                        font.bold: modelData.bold || false
                        font.italic: modelData.italic || false
                        font.underline: modelData.underline || false
                        color: fmtBtnHover.containsMouse ? root.accentColor : root.fgColor
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

                onTextChanged: {
                  if (root.notesLoaded) {
                    notesAutosaveTimer.restart()
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
              text: "Super+Alt+T: Toggle | Super+Alt+N: Tab | Super+Alt+P: Pin"
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
