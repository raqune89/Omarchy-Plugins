import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.tun-switcher"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool vpnActive: false
  property string vpnLatency: "--"
  property string vpnType: "Disconnected"

  Process {
    id: vpnChecker
    command: ["sh", "-c", "ip link show tun0 2>/dev/null && pgrep -a openvpn || true"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var str = text.trim()
        root.vpnActive = str.indexOf("tun0") >= 0
        if (str.indexOf("htb") >= 0) root.vpnType = "HackTheBox"
        else if (str.indexOf("thm") >= 0 || str.indexOf("tryhackme") >= 0) root.vpnType = "TryHackMe"
        else if (root.vpnActive) root.vpnType = "OpenVPN Tunnel"
        else root.vpnType = "Disconnected"
      }
    }
  }

  Process {
    id: pingChecker
    command: ["sh", "-c", "if ip link show tun0 >/dev/null 2>&1; then ping -c 1 -W 1 10.10.10.10 2>/dev/null | grep -oP '(?<=time=)[0-9.]+' || echo '--'; else echo '--'; fi"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var res = text.trim()
        root.vpnLatency = res !== "" && res !== "--" ? Math.round(Number(res)) + "ms" : "--"
      }
    }
  }

  Timer {
    interval: 3500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!vpnChecker.running) vpnChecker.running = true
      if (!pingChecker.running) pingChecker.running = true
    }
  }

  function disconnectVpn() {
    Util.execArgv(["sh", "-c", "sudo pkill openvpn || pkexec pkill openvpn"])
    vpnChecker.running = true
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: "VPN: " + root.vpnType + (root.vpnLatency !== "--" ? (" (" + root.vpnLatency + ")") : "")
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("tun-switcher-cad.svg")
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
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "CTF VPN Switcher"
          meta: root.vpnType
          detail: root.vpnLatency
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("tun-switcher-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            text: "OpenVPN Terminal (~/htb)"
            bordered: true
            onClicked: {
              Util.execArgv(["omarchy-launch-floating-terminal", "sh", "-c", "cd ~/htb 2>/dev/null || cd ~/Downloads 2>/dev/null || cd ~; ls -la *.ovpn 2>/dev/null; exec bash"])
              root.close()
            }
          }

          Button {
            visible: root.vpnActive
            text: "Disconnect"
            bordered: true
            onClicked: root.disconnectVpn()
          }
        }
      }
    }
  }
}
