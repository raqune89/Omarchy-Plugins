import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.selective-reading"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/selective-reading/state.json"
  readonly property string cliPath: Quickshell.env("HOME") + "/.local/bin/selective-reading"

  property bool isPlaying: false
  property bool isPaused: false
  property string currentVoice: "shayne_topp"
  property string currentVoiceName: "Shayne Topp"
  property int currentVolume: 100
  property string lastSnippet: ""

  readonly property var voices: [
    { id: "shayne_topp", name: "Shayne Topp", desc: "Adaptive Energy (US M)" },
    { id: "angela_giarratana", name: "Angela Giarratana", desc: "Bright & Expressive (US F)" },
    { id: "amanda_lehan_canto", name: "Amanda Lehan-Canto", desc: "Warm Storyteller (US F)" }
  ]

  readonly property var volumes: [
    { label: "Mute", value: 0 },
    { label: "50%", value: 50 },
    { label: "75%", value: 75 },
    { label: "100%", value: 100 }
  ]

  function neutralizeMarkup(val) {
    if (!val) return ""
    return String(val).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var data = JSON.parse(text())
        root.isPlaying = Boolean(data.isPlaying)
        root.isPaused = Boolean(data.isPaused)
        if (data.voice) root.currentVoice = String(data.voice)
        if (data.voiceName) root.currentVoiceName = String(data.voiceName)
        if (data.volume !== undefined) root.currentVolume = Math.round(Number(data.volume))
        if (data.textSnippet !== undefined) root.lastSnippet = String(data.textSnippet)
      } catch (e) {}
    }
    onFileChanged: reload()
  }

  function selectVoice(voiceId, voiceName) {
    root.currentVoice = voiceId
    root.currentVoiceName = voiceName
    Util.execArgv([root.cliPath, "set-voice", voiceId])
  }

  function previewVoice(voiceId) {
    Util.execArgv([root.cliPath, "preview", voiceId])
  }

  function setVolume(vol) {
    var v = Math.max(0, Math.min(100, Math.round(vol)))
    root.currentVolume = v
    Util.execArgv([root.cliPath, "set-volume", String(v)])
  }

  function triggerRead() {
    Util.execArgv([root.cliPath, "read"])
  }

  function triggerStop() {
    Util.execArgv([root.cliPath, "stop"])
  }

  function triggerToggle() {
    Util.execArgv([root.cliPath, "toggle"])
  }

  function triggerPause() {
    Util.execArgv([root.cliPath, "pause"])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: root.isPlaying
      ? (root.isPaused
          ? ("Selective Reading: Paused (" + root.neutralizeMarkup(root.currentVoiceName) + ") [SUPER+R]")
          : ("Selective Reading: Speaking (" + root.neutralizeMarkup(root.currentVoiceName) + ") [SUPER+R to pause]"))
      : ("Selective Reading: " + root.neutralizeMarkup(root.currentVoiceName) + " [SUPER+SHIFT+R]")
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("selective-reading-cad.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }
    onPressed: function(b) {
      if (b === Qt.RightButton) root.triggerToggle()
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
        spacing: Style.space(10)

        PanelHero {
          width: parent.width
          title: "Selective Reading"
          meta: root.isPlaying
            ? ((root.isPaused ? "PAUSED • " : "SPEAKING • ") + root.neutralizeMarkup(root.currentVoiceName).toUpperCase())
            : ("VOICE: " + root.neutralizeMarkup(root.currentVoiceName).toUpperCase() + " • SUPER+SHIFT+R")
          detail: root.isPlaying ? (root.isPaused ? "PAUSED" : "LIVE") : "READY"
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("selective-reading-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: Math.floor((parent.width - Style.space(16)) * 0.44)
            text: "Read Text"
            bordered: true
            selected: root.isPlaying && !root.isPaused
            onClicked: root.triggerRead()
          }

          Button {
            width: Math.floor((parent.width - Style.space(16)) * 0.30)
            text: root.isPaused ? "Resume" : "Pause"
            bordered: true
            selected: root.isPaused
            enabled: root.isPlaying
            onClicked: root.triggerPause()
          }

          Button {
            width: parent.width - Math.floor((parent.width - Style.space(16)) * 0.44) - Math.floor((parent.width - Style.space(16)) * 0.30) - Style.space(16)
            text: "Stop"
            bordered: true
            enabled: root.isPlaying
            onClicked: root.triggerStop()
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        PanelSectionHeader {
          text: "CLONED CELEBRITY VOICES"
          foreground: Commons.Color.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.voices
            delegate: Row {
              width: column.width
              spacing: Style.space(6)

              Button {
                width: column.width - sampleBtn.width - Style.space(6)
                text: modelData.name + " — " + modelData.desc
                bordered: true
                selected: root.currentVoice === modelData.id
                onClicked: root.selectVoice(modelData.id, modelData.name)
              }

              Button {
                id: sampleBtn
                width: Style.space(68)
                text: "Sample"
                bordered: true
                onClicked: root.previewVoice(modelData.id)
              }
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width - Style.space(56) - Style.space(8)
            textFormat: Text.PlainText
            text: "VOLUME"
            color: Commons.Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            elide: Text.ElideRight
            clip: true
          }

          Text {
            id: volValueText
            width: Style.space(56)
            textFormat: Text.PlainText
            text: (volSlider.dragging ? Math.round(volSlider.liveValue) : root.currentVolume) + "%"
            color: Qt.darker(Commons.Color.foreground, 1.25)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            clip: true
          }
        }

        PanelSlider {
          id: volSlider
          bar: root.bar
          width: parent.width
          minimum: 0
          maximum: 100
          step: 5
          integer: true
          value: root.currentVolume
          onMoved: function(v) { root.setVolume(v) }
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.volumes
            delegate: Button {
              width: Math.floor((column.width - Style.space(18)) / 4)
              text: modelData.label
              bordered: true
              selected: root.currentVolume === modelData.value
              onClicked: root.setVolume(modelData.value)
            }
          }
        }

        PanelSeparator {
          visible: root.lastSnippet !== ""
          foreground: Commons.Color.foreground
        }

        Text {
          visible: root.lastSnippet !== ""
          width: parent.width
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight
          clip: true
          color: Qt.darker(Commons.Color.foreground, 1.25)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          text: "Last read: \"" + root.lastSnippet + "\""
        }
      }
    }
  }
}
