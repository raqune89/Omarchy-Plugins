import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentBackgroundLink: stateHome + "/omarchy/current/background"

  property string themeName: ""
  property var allWallpapers: []
  property var monitorOverrides: ({})

  property string currentBackground: ""
  property bool instantSwitch: false
  property int backgroundVersion: 0
  property int revealStartedVersion: -1
  property int pendingThemeVersion: -1
  property string pendingColorsRaw: ""
  property string pendingShellRaw: ""

  function imageUrl(path) {
    return Util.fileUrl(path)
  }

  function refreshBackground() {
    if (!syncProc.running) syncProc.running = true
  }

  function setBackground(path, instant) {
    path = String(path || "").trim()
    if (!path) return
    instantSwitch = instant
    currentBackground = path
    backgroundVersion += 1
    refreshBackground()
  }

  function getScreenIndex(screen) {
    if (!screen || !Quickshell.screens || Quickshell.screens.length <= 1) return 0
    var list = []
    for (var i = 0; i < Quickshell.screens.length; i++) {
      list.push(Quickshell.screens[i])
    }
    list.sort(function(a, b) { return (a.x || 0) - (b.x || 0) })
    for (var j = 0; j < list.length; j++) {
      if (list[j].name === screen.name) return j
    }
    return 0
  }

  function getBackgroundForScreen(screen, baseBg) {
    if (!screen) return baseBg || root.currentBackground

    var screenName = String(screen.name || "").trim()
    if (screenName && root.monitorOverrides[screenName]) {
      return root.monitorOverrides[screenName]
    }

    var screens = []
    for (var i = 0; i < Quickshell.screens.length; i++) {
      screens.push(Quickshell.screens[i])
    }
    screens.sort(function(a, b) { return (a.x || 0) - (b.x || 0) })

    var screenIndex = 0
    for (var s = 0; s < screens.length; s++) {
      if (screens[s].name === screen.name) {
        screenIndex = s
        break
      }
    }

    if (screens.length <= 1 || !root.allWallpapers || root.allWallpapers.length <= 1) {
      return baseBg || root.currentBackground
    }

    // Reforger dual-screen arsenal pairing
    if (root.themeName === "reforger") {
      var usList = []
      var sovList = []
      for (var w = 0; w < root.allWallpapers.length; w++) {
        var fn = root.allWallpapers[w].toLowerCase()
        if (fn.indexOf("m16a2") !== -1 || fn.indexOf("m21") !== -1 ||
            fn.indexOf("m249") !== -1 || fn.indexOf("m60") !== -1 ||
            fn.indexOf("m72") !== -1 || fn.indexOf("m9") !== -1) {
          usList.push(root.allWallpapers[w])
        } else {
          sovList.push(root.allWallpapers[w])
        }
      }

      if (usList.length > 0 && sovList.length > 0) {
        var cur = (baseBg || root.currentBackground || "")
        var curIdx = 0
        var found = false
        for (var u = 0; u < usList.length; u++) {
          if (usList[u] === cur) { curIdx = u; found = true; break }
        }
        if (!found) {
          for (var sv = 0; sv < sovList.length; sv++) {
            if (sovList[sv] === cur) { curIdx = sv; break }
          }
        }

        if (screenIndex === 0) {
          // Left monitor (DP-3): US weaponry
          return usList[curIdx % usList.length]
        } else {
          // Right monitor (HDMI-A-1): Soviet / tactical recon gear
          return sovList[curIdx % sovList.length]
        }
      }
    }

    // Generic multi-monitor pairing for any theme
    var total = root.allWallpapers.length
    var curPath = (baseBg || root.currentBackground || "")
    var baseIdx = root.allWallpapers.indexOf(curPath)
    if (baseIdx === -1) baseIdx = 0

    var offset = Math.max(1, Math.floor(total / screens.length))
    var targetIdx = (baseIdx + screenIndex * offset) % total
    return root.allWallpapers[targetIdx]
  }

  function setPendingTheme(colorsB64, shellB64) {
    pendingColorsRaw = Util.decodeBase64(colorsB64)
    pendingShellRaw = Util.decodeBase64(shellB64)
    pendingThemeVersion = backgroundVersion
    pendingThemeFallbackTimer.restart()
  }

  function applyPendingTheme() {
    if (pendingThemeVersion < 0) return
    pendingThemeFallbackTimer.stop()
    Commons.Color.loadColors(pendingColorsRaw)
    Commons.Color.loadShell(pendingShellRaw)
    Style.scheduleRefresh()
    pendingThemeVersion = -1
    pendingColorsRaw = ""
    pendingShellRaw = ""
  }

  function transitionBackgroundWithTheme(fromPath, path, finalPath, colorsB64, shellB64) {
    setPendingTheme(colorsB64, shellB64)
    setBackground(finalPath || path, false)
  }

  function openSelector() {
    if (!bgSwitchProc.running) bgSwitchProc.running = true
  }

  function openThemeSwitcher() {
    if (!themeSwitchProc.running) themeSwitchProc.running = true
  }

  Process {
    id: bgSwitchProc
    command: ["bash", "-c", "background=$(omarchy-theme-bg-switcher); [[ -n $background ]] && omarchy-theme-bg-set \"$background\""]
    onExited: root.refreshBackground()
  }

  Process {
    id: themeSwitchProc
    command: ["bash", "-c", "theme=$(omarchy-theme-switcher); [[ -n $theme ]] && omarchy-theme-set \"$theme\" >/dev/null 2>&1 &"]
    onExited: root.refreshBackground()
  }

  Process {
    id: syncProc
    command: ["bash", "-c", "
      theme=$(cat \"$HOME/.local/state/omarchy/current/theme.name\" 2>/dev/null)
      link=$(readlink -f \"$HOME/.local/state/omarchy/current/background\" 2>/dev/null)
      echo \"THEME:$theme\"
      echo \"CURRENT:$link\"
      for mon_link in \"$HOME/.local/state/omarchy/current\"/background-*; do
        if [[ -f \"$mon_link\" ]]; then
          mon_name=$(basename \"$mon_link\" | sed 's/^background-//')
          target=$(readlink -f \"$mon_link\")
          echo \"OVERRIDE:$mon_name:$target\"
        fi
      done
      echo \"FILES:\"
      find -L \"$HOME/.local/state/omarchy/current/theme/backgrounds\" \"$HOME/.config/omarchy/backgrounds/$theme\" -maxdepth 1 -type f \\( -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.png\" -o -iname \"*.gif\" -o -iname \"*.webp\" \\) 2>/dev/null | sort -u
    "]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (text || "").split("\n")
        var theme = ""
        var cur = ""
        var overrides = {}
        var files = []
        var inFiles = false
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (!line) continue
          if (line.indexOf("THEME:") === 0) {
            theme = line.substring(6)
          } else if (line.indexOf("CURRENT:") === 0) {
            cur = line.substring(8)
          } else if (line.indexOf("OVERRIDE:") === 0) {
            var parts = line.substring(9).split(":")
            if (parts.length >= 2) {
              overrides[parts[0]] = parts.slice(1).join(":")
            }
          } else if (line === "FILES:") {
            inFiles = true
          } else if (inFiles) {
            files.push(line)
          }
        }
        root.themeName = theme
        root.monitorOverrides = overrides
        root.allWallpapers = files
        if (cur && (!root.currentBackground || root.currentBackground !== cur)) {
          root.currentBackground = cur
        }
      }
    }
  }

  IpcHandler {
    target: "background"

    function getStatus(): string {
      var res = ["Theme: " + root.themeName, "Base: " + root.currentBackground]
      for (var s = 0; s < Quickshell.screens.length; s++) {
        var sc = Quickshell.screens[s]
        var bg = root.getBackgroundForScreen(sc, root.currentBackground)
        res.push("Screen " + sc.name + " (x=" + sc.x + "): " + bg)
      }
      return res.join("\n")
    }

    function refresh(): void {
      root.refreshBackground()
    }

    function set(path: string): void {
      root.setBackground(path, false)
    }

    function setInstant(path: string): void {
      root.setBackground(path, true)
    }

    function transition(fromPath: string, path: string): void {
      root.setBackground(path, false)
    }

    function themeTransition(fromPath: string, path: string, finalPath: string, colorsB64: string, shellB64: string): void {
      root.transitionBackgroundWithTheme(fromPath, path, finalPath, colorsB64, shellB64)
    }
  }

  Timer {
    id: pendingThemeFallbackTimer
    interval: 300
    repeat: false
    onTriggered: root.applyPendingTheme()
  }

  Component.onCompleted: refreshBackground()

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      screen: modelData
      visible: !remapGuard.remapping
      anchors { top: true; bottom: true; left: true; right: true }

      ScreenMoveRemap {
        id: remapGuard
        window: panel
      }
      color: "transparent"
      updatesEnabled: true

      property string displayedBg: ""
      property string incomingBg: ""
      property string oldBg: ""
      property real revealProgress: 1
      property bool finishingTransition: false
      property bool maskReady: false

      readonly property string targetBg: {
        var bg = root.getBackgroundForScreen(panel.screen, root.currentBackground);
        console.log("PANEL SCREEN " + (panel.screen ? panel.screen.name : "?") + " -> " + bg);
        return bg;
      }

      onTargetBgChanged: {
        if (targetBg) {
          panel.transitionTo(targetBg, root.instantSwitch)
        }
      }

      Component.onCompleted: {
        if (targetBg) {
          panel.transitionTo(targetBg, true)
        }
      }

      function transitionTo(path, instant) {
        path = String(path || "").trim()
        if (!path || path === panel.displayedBg) return
        panelRevealAnim.stop()
        panel.finishingTransition = false

        if (instant || !panel.displayedBg) {
          panel.oldBg = ""
          panel.incomingBg = ""
          panel.displayedBg = path
          panel.revealProgress = 1
          return
        }

        panel.oldBg = panel.displayedBg
        panel.incomingBg = path
        panel.revealProgress = 0
        panel.maskReady = false
        panel.maybeStartReveal()
      }

      function maybeStartReveal() {
        if (!panel.incomingBg || panel.revealProgress !== 0 || panel.maskReady) return
        if (incomingFrame.status !== Image.Ready) return
        Qt.callLater(function() {
          if (!panel.incomingBg || panel.revealProgress !== 0 || panel.maskReady) return
          if (incomingFrame.status !== Image.Ready) return
          panel.maskReady = true
          root.applyPendingTheme()
          panelRevealAnim.restart()
        })
      }

      NumberAnimation {
        id: panelRevealAnim
        target: panel
        property: "revealProgress"
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.InOutCubic
        onFinished: {
          if (panel.incomingBg) {
            panel.displayedBg = panel.incomingBg
            panel.finishingTransition = true
          }
          panel.revealProgress = 1
        }
      }

      WlrLayershell.namespace: "omarchy-background"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Image {
        id: base
        anchors.fill: parent
        source: root.imageUrl(panel.displayedBg)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        onStatusChanged: {
          if (status === Image.Ready && panel.finishingTransition) {
            panel.incomingBg = ""
            panel.oldBg = ""
            panel.finishingTransition = false
          }
        }
      }

      Image {
        id: oldFrame
        anchors.fill: parent
        source: root.imageUrl(panel.oldBg)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        visible: panel.oldBg !== "" && panel.revealProgress < 1
        onStatusChanged: panel.maybeStartReveal()
      }

      Item {
        id: incomingLayer
        anchors.fill: parent
        visible: panel.incomingBg !== "" && incomingFrame.status === Image.Ready && (panel.revealProgress >= 1 || panel.maskReady)
        layer.enabled: panel.incomingBg !== "" && panel.revealProgress < 1
        layer.smooth: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: revealMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.02
        }

        Image {
          id: incomingFrame
          anchors.fill: parent
          source: root.imageUrl(panel.incomingBg)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false
          smooth: true
          mipmap: true
          onStatusChanged: panel.maybeStartReveal()
        }
      }

      Item {
        id: revealMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        readonly property real slant: -0.18
        readonly property real centerTop: width / 2 - slant * height / 2
        readonly property real centerBottom: width / 2 + slant * height / 2
        readonly property real reach: width / 2 + Math.abs(slant) * height / 2 + 4
        readonly property real spread: reach * panel.revealProgress

        Shape {
          anchors.fill: parent
          antialiasing: true
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            startX: revealMask.centerTop - revealMask.spread; startY: 0
            PathLine { x: revealMask.centerTop + revealMask.spread; y: 0 }
            PathLine { x: revealMask.centerBottom + revealMask.spread; y: revealMask.height }
            PathLine { x: revealMask.centerBottom - revealMask.spread; y: revealMask.height }
            PathLine { x: revealMask.centerTop - revealMask.spread; y: 0 }
          }
        }
      }

      Connections {
        target: panel
        function onIncomingBgChanged() {
          panel.maskReady = false
          panel.maybeStartReveal()
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onDoubleClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) root.openThemeSwitcher()
          else root.openSelector()
          mouse.accepted = true
        }
      }
    }
  }
}
