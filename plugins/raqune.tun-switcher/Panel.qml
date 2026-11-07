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
        else if (str.indexOf("thm") >= 0 || str.indexOf("tryhackme") >= 0 || str.indexOf("regular.ovpn") >= 0) root.vpnType = "TryHackMe / CTF"
        else if (root.vpnActive) root.vpnType = "OpenVPN Tunnel"
        else root.vpnType = "Disconnected"
      }
    }
  }

  Process {
    id: pingChecker
    command: ["sh", "-c", "if ip link show tun0 >/dev/null 2>&1; then gw=$(ip route show dev tun0 2>/dev/null | awk 'NR==1 {print $1}' | sed 's|/.*||'); target=${gw:-10.10.10.10}; ping -c 1 -W 1 \"$target\" 2>/dev/null | grep -oP '(?<=time=)[0-9.]+' || echo '--'; else echo '--'; fi"]
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

  function connectThmVpn() {
    var cmd = "echo $$ > /tmp/omarchy-thmvpn-term.pid; " +
              "shopt -s expand_aliases; " +
              "[ -f ~/.bashrc ] && source ~/.bashrc; " +
              "echo '==> Running THMvpn...'; " +
              "THMvpn; " +
              "echo '[+] THMvpn connected in background.'; " +
              "exec bash -i"
    Util.execArgv([
      "setsid",
      "uwsm-app",
      "--",
      "xdg-terminal-exec",
      "--app-id=org.omarchy.thmvpn",
      "--title=THMvpn",
      "-e",
      "bash",
      "-ic",
      cmd
    ])
    vpnChecker.running = true
    root.close()
  }

  function disconnectThmVpn() {
    var stopCmd = "shopt -s expand_aliases; " +
                  "[ -f ~/.bashrc ] && source ~/.bashrc; " +
                  "THMstop 2>/dev/null || sudo -n pkill openvpn 2>/dev/null; " +
                  "hyprctl dispatch closewindow class:org.omarchy.thmvpn >/dev/null 2>&1 || true; " +
                  "if [ -f /tmp/omarchy-thmvpn-term.pid ]; then " +
                  "  tpid=$(cat /tmp/omarchy-thmvpn-term.pid 2>/dev/null); " +
                  "  [ -n \"$tpid\" ] && kill -TERM \"$tpid\" 2>/dev/null || true; " +
                  "  rm -f /tmp/omarchy-thmvpn-term.pid; " +
                  "fi"
    Util.execArgv(["bash", "-ic", stopCmd])
    vpnChecker.running = true
    root.close()
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
    onPressed: function(b) {
      if (!vpnChecker.running) vpnChecker.running = true
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
            text: "Connect (THMvpn)"
            bordered: true
            selected: root.vpnActive
            onClicked: root.connectThmVpn()
          }

          Button {
            text: "Disconnect (THMstop)"
            bordered: true
            onClicked: root.disconnectThmVpn()
          }
        }
      }
    }
  }
}
