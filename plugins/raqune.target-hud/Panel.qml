import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.target-hud"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string tun0Ip: ""
  property string targetIp: ""
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/ctf/target.json"

  Process {
    id: tunChecker
    command: ["sh", "-c", "ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' || echo ''"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { root.tun0Ip = text.trim() }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!tunChecker.running) tunChecker.running = true }
  }

  FileView {
    id: targetFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var data = JSON.parse(text())
        root.targetIp = data.target || ""
      } catch(e) { root.targetIp = "" }
    }
    onFileChanged: reload()
  }

  function setTarget(ip) {
    root.targetIp = ip.trim()
    targetFile.setText(JSON.stringify({ target: root.targetIp }) + "\n")
  }

  function copyToClipboard(textToCopy) {
    if (!textToCopy) return
    Util.execArgv(["sh", "-c", "printf '%s' \"$1\" | wl-copy && omarchy-notification-send 'Target HUD' \"Copied: $1\"", "copy", textToCopy])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.targetIp !== "" ? ("Target: " + root.targetIp) : (root.tun0Ip !== "" ? ("tun0: " + root.tun0Ip) : "Target HUD")
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("target-hud-cad.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }
    onPressed: function(b) {
      if (b === Qt.RightButton && root.targetIp !== "") root.copyToClipboard(root.targetIp)
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
    contentWidth: panel.fittedContentWidth(Style.space(360))
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
          title: "Target HUD"
          meta: root.tun0Ip !== "" ? ("TUN0: " + root.tun0Ip) : "VPN DISCONNECTED"
          detail: root.targetIp !== "" ? root.targetIp : "NO TARGET"
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("target-hud-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(8)

          TextField {
            id: targetInput
            width: parent.width - setBtn.implicitWidth - Style.space(8)
            text: root.targetIp
            placeholderText: "Target IP / Host (e.g. 10.10.11.23)"
            onAccepted: root.setTarget(text)
          }

          Button {
            id: setBtn
            text: "Set"
            bordered: true
            onClicked: root.setTarget(targetInput.text)
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: Math.floor((parent.width - Style.space(16)) / 3)
            text: "Copy Target"
            bordered: true
            onClicked: root.copyToClipboard(root.targetIp)
          }
          Button {
            width: Math.floor((parent.width - Style.space(16)) / 3)
            text: "Copy tun0"
            bordered: true
            onClicked: root.copyToClipboard(root.tun0Ip)
          }
          Button {
            width: parent.width - 2 * Math.floor((parent.width - Style.space(16)) / 3) - Style.space(16)
            text: "Nmap Scan"
            bordered: true
            onClicked: {
              if (root.targetIp === "") return
              Util.execArgv(["setsid", "uwsm-app", "--", "xdg-terminal-exec", "--app-id=org.omarchy.terminal", "--title=Target HUD Nmap", "-e", "bash", "-c", "nmap -sC -sV " + root.targetIp + "; exec bash"])
              root.close()
            }
          }
        }
      }
    }
  }
}
