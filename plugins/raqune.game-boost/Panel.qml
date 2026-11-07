import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.game-boost"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool gameActive: false

  Process {
    id: gameCheck
    command: ["sh", "-c", "gamemoded -s 2>/dev/null || (pgrep -i steam_app || pgrep -i wineserver || pgrep -i gamescope || echo '')"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = text.trim()
        var isActive = out.indexOf("is active") >= 0 || (out !== "" && out.indexOf("inactive") < 0)
        if (isActive !== root.gameActive) {
          root.gameActive = isActive
          root.applyCompositorBoost(root.gameActive)
        }
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!gameCheck.running) gameCheck.running = true }
  }

  function applyCompositorBoost(enable) {
    if (enable) {
      Util.execArgv(["hyprctl", "keyword", "decoration:blur:enabled", "false"])
      Util.execArgv(["hyprctl", "keyword", "animations:enabled", "false"])
    } else {
      Util.execArgv(["hyprctl", "keyword", "decoration:blur:enabled", "true"])
      Util.execArgv(["hyprctl", "keyword", "animations:enabled", "true"])
    }
  }

  function toggleManualBoost() {
    root.gameActive = !root.gameActive
    root.applyCompositorBoost(root.gameActive)
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.gameActive ? "Game Boost: ACTIVE (Max FPS)" : "Game Boost: Desktop Mode"
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("game-boost-cad.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleManualBoost()
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
          title: "Game Boost HUD"
          meta: root.gameActive ? "LOW-LATENCY COMPOSITOR ACTIVE" : "AUTO-DETECTS STEAM & GAMEMODE"
          detail: root.gameActive ? "BOOST" : "IDLE"
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("game-boost-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            text: root.gameActive ? "Restore Desktop Effects" : "Force Enable FPS Boost"
            bordered: true
            selected: root.gameActive
            onClicked: root.toggleManualBoost()
          }
        }
      }
    }
  }
}
