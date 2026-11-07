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
  property var ovpnProfiles: []

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
    id: profileScanner
    command: ["sh", "-c", "find ~/Documents ~/htb ~/Downloads ~ -maxdepth 2 -type f -name '*.ovpn' 2>/dev/null | awk '!seen[$0]++' | head -n 5"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.trim().split("\n")
        var list = []
        for (var i = 0; i < lines.length; i++) {
          var p = lines[i].trim()
          if (p !== "") {
            var base = p.split("/").pop()
            list.push({ path: p, name: base })
          }
        }
        root.ovpnProfiles = list
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
      if (!profileScanner.running) profileScanner.running = true
    }
  }

  function launchOpenVpnTerminal() {
    var script = "for d in \"$HOME/htb\" \"$HOME/Documents/THM\" \"$HOME/Documents\" \"$HOME/Downloads\" \"$HOME\"; do " +
                 "if [ -d \"$d\" ] && ls \"$d\"/*.ovpn >/dev/null 2>&1; then cd \"$d\"; break; fi; " +
                 "done; " +
                 "echo '=== CTF OpenVPN Profiles ==='; " +
                 "ls -1 *.ovpn 2>/dev/null || find ~/Documents ~/htb ~/Downloads -maxdepth 2 -name '*.ovpn' 2>/dev/null; " +
                 "echo ''; echo 'Run: sudo openvpn --config <profile.ovpn>'; echo ''; exec bash"
    Util.execArgv([
      "setsid",
      "uwsm-app",
      "--",
      "xdg-terminal-exec",
      "--app-id=org.omarchy.terminal",
      "--title=OpenVPN Terminal",
      "-e",
      "bash",
      "-c",
      script
    ])
    root.close()
  }

  function connectProfile(ovpnPath) {
    var escaped = String(ovpnPath).replace(/(["\\$`])/g, "\\$1")
    var script = "echo \"Connecting OpenVPN: " + escaped + "\"; sudo openvpn --config \"" + escaped + "\"; exec bash"
    Util.execArgv([
      "setsid",
      "uwsm-app",
      "--",
      "xdg-terminal-exec",
      "--app-id=org.omarchy.terminal",
      "--title=OpenVPN Tunnel",
      "-e",
      "bash",
      "-c",
      script
    ])
    root.close()
  }

  function disconnectVpn() {
    Util.execArgv(["sh", "-c", "sudo -n pkill openvpn 2>/dev/null || pkexec pkill openvpn"])
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
    onPressed: function(b) {
      if (!profileScanner.running) profileScanner.running = true
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
        spacing: Style.space(10)

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
            text: "OpenVPN Terminal"
            bordered: true
            onClicked: root.launchOpenVpnTerminal()
          }

          Button {
            visible: root.vpnActive
            text: "Disconnect"
            bordered: true
            onClicked: root.disconnectVpn()
          }
        }

        PanelSeparator {
          visible: root.ovpnProfiles.length > 0
          foreground: Commons.Color.foreground
        }

        PanelSectionHeader {
          visible: root.ovpnProfiles.length > 0
          text: "DISCOVERED PROFILES (.OVPN)"
          foreground: Commons.Color.foreground
        }

        Column {
          visible: root.ovpnProfiles.length > 0
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.ovpnProfiles
            delegate: Button {
              required property var modelData
              width: column.width
              text: "Connect: " + modelData.name
              bordered: true
              onClicked: root.connectProfile(modelData.path)
            }
          }
        }
      }
    }
  }
}
