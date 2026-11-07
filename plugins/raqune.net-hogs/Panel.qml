import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.net-hogs"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string rxSpeed: "0 B/s"
  property string txSpeed: "0 B/s"
  property double lastRx: 0
  property double lastTx: 0
  property double lastTime: 0

  Process {
    id: netPoll
    command: ["sh", "-c", "awk 'NR>2 && $1 !~ /lo:/ {rx+=$2; tx+=$10} END {print rx, tx}' /proc/net/dev"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parts = text.trim().split(/\s+/)
        if (parts.length >= 2) {
          var rx = Number(parts[0])
          var tx = Number(parts[1])
          var now = Date.now() / 1000
          if (root.lastTime > 0) {
            var dt = Math.max(1, now - root.lastTime)
            var rxRate = Math.max(0, (rx - root.lastRx) / dt)
            var txRate = Math.max(0, (tx - root.lastTx) / dt)
            root.rxSpeed = root.formatRate(rxRate)
            root.txSpeed = root.formatRate(txRate)
          }
          root.lastRx = rx
          root.lastTx = tx
          root.lastTime = now
        }
      }
    }
  }

  function formatRate(bytes) {
    if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB/s"
    if (bytes >= 1024) return (bytes / 1024).toFixed(0) + " KB/s"
    return bytes.toFixed(0) + " B/s"
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!netPoll.running) netPoll.running = true }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: "Net Hogs: ↓ " + root.rxSpeed + " · ↑ " + root.txSpeed
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("net-hogs-cad.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
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
          title: "Bandwidth Telemetry"
          meta: "LIVE INTERFACE THROUGHPUT"
          detail: root.rxSpeed
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("net-hogs-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(16)

          Text {
            textFormat: Text.PlainText
            text: "↓ Download: " + root.rxSpeed
            color: Commons.Color.accent
            font.family: Style.font.family
            font.bold: true
            font.pixelSize: Style.font.body
          }

          Text {
            textFormat: Text.PlainText
            text: "↑ Upload: " + root.txSpeed
            color: Commons.Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
          }
        }
      }
    }
  }
}
