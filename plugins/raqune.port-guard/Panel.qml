import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.port-guard"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property var portList: []
  property int openCount: 0

  Process {
    id: portScanner
    command: ["sh", "-c", "ss -tlpn 2>/dev/null | awk 'NR>1 {print $4, $6}' | sed 's/.*://' | sort -n -u | head -n 12"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.trim().split("\n")
        var res = []
        for (var i = 0; i < lines.length; i++) {
          var l = lines[i].trim()
          if (l !== "") {
            var parts = l.split(/\s+/)
            res.push({ port: parts[0], proc: parts[1] || "listening" })
          }
        }
        root.portList = res
        root.openCount = res.length
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!portScanner.running) portScanner.running = true }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: "Port Guard (" + root.openCount + " listening)"
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("port-guard-cad.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }
    onPressed: function(b) {
      if (!portScanner.running) portScanner.running = true
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
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
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Port Guard"
          meta: "ACTIVE TCP LISTENERS"
          detail: String(root.openCount)
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("port-guard-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Repeater {
          model: root.portList
          delegate: Row {
            required property var modelData
            width: column.width
            spacing: Style.space(10)

            Text {
              textFormat: Text.PlainText
              text: ":" + modelData.port
              color: Commons.Color.accent
              font.family: Style.font.family
              font.bold: true
              font.pixelSize: Style.font.body
              width: Style.space(64)
            }

            Text {
              textFormat: Text.PlainText
              text: modelData.proc
              color: Qt.darker(Commons.Color.foreground, 1.3)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              width: column.width - Style.space(74)
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}
