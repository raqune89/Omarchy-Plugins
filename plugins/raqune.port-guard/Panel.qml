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
    command: [
      "sh",
      "-c",
      "ss -tlpn 2>/dev/null | awk 'NR>1 { local_ep=$4; port=local_ep; sub(/.*:/, \"\", port); addr=local_ep; sub(/:[0-9]+$/, \"\", addr); sub(/%.*/, \"\", addr); proc=\"\"; if ($0 ~ /users:\\(\\(\"/) { tmp=$0; sub(/.*users:\\(\\(\"/, \"\", tmp); app=tmp; sub(/\".*/, \"\", app); pid=tmp; if (pid ~ /pid=[0-9]+/) { sub(/.*pid=/, \"\", pid); sub(/[^0-9].*/, \"\", pid); proc=app \" (pid \" pid \")\" } else { proc=app } } if (port ~ /^[0-9]+$/) { if (!(port in seen) || (seen_proc[port] == \"\" && proc != \"\")) { seen[port]=1; seen_proc[port]=proc; seen_addr[port]=addr } } } END { for (p in seen) print p \"|\" seen_proc[p] \"|\" seen_addr[p] }' | sort -t'|' -k1,1n | head -n 14 | while IFS='|' read -r port proc addr; do if [ -z \"$proc\" ]; then case \"$port\" in 53) proc=\"systemd-resolved (DNS)\" ;; 631) proc=\"cupsd (IPP Printing)\" ;; 22) proc=\"sshd (SSH)\" ;; 80) proc=\"HTTP Server\" ;; 443) proc=\"HTTPS Server\" ;; 3306) proc=\"mysqld / mariadb\" ;; 5432) proc=\"PostgreSQL\" ;; 6379) proc=\"redis-server\" ;; 8000|8080|8888) proc=\"HTTP Web Server\" ;; *) svc=$(getent services \"${port}/tcp\" 2>/dev/null | awk '{print $1}'); if [ -n \"$svc\" ]; then proc=\"${svc} (system)\"; else proc=\"system service\"; fi ;; esac; fi; printf '%s|%s|%s\\n' \"$port\" \"$proc\" \"$addr\"; done"
    ]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.trim().split("\n")
        var res = []
        for (var i = 0; i < lines.length; i++) {
          var l = lines[i].trim()
          if (l !== "") {
            var parts = l.split("|")
            res.push({
              port: parts[0] || "",
              service: parts[1] || "listening",
              addr: parts[2] || "0.0.0.0"
            })
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
        spacing: Style.space(8)

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

        Row {
          width: column.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "PORT"
            color: Qt.darker(Commons.Color.foreground, 1.4)
            font.family: Style.font.family
            font.bold: true
            font.pixelSize: Style.font.caption
            width: Style.space(62)
          }

          Text {
            textFormat: Text.PlainText
            text: "APP / SERVICE"
            color: Qt.darker(Commons.Color.foreground, 1.4)
            font.family: Style.font.family
            font.bold: true
            font.pixelSize: Style.font.caption
            width: Style.space(182)
          }

          Text {
            textFormat: Text.PlainText
            text: "BIND IP"
            color: Qt.darker(Commons.Color.foreground, 1.4)
            font.family: Style.font.family
            font.bold: true
            font.pixelSize: Style.font.caption
            width: Math.max(Style.space(60), column.width - Style.space(260))
          }
        }

        Repeater {
          model: root.portList
          delegate: Row {
            required property var modelData
            width: column.width
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: ":" + modelData.port
              color: Commons.Color.accent
              font.family: Style.font.family
              font.bold: true
              font.pixelSize: Style.font.body
              width: Style.space(62)
              elide: Text.ElideRight
              clip: true
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              textFormat: Text.PlainText
              text: modelData.service
              color: Commons.Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              width: Style.space(182)
              elide: Text.ElideRight
              clip: true
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              textFormat: Text.PlainText
              text: modelData.addr
              color: Qt.darker(Commons.Color.foreground, 1.35)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              width: Math.max(Style.space(60), column.width - Style.space(260))
              elide: Text.ElideRight
              clip: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}
