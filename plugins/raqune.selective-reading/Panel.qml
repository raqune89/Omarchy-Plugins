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
  property string currentVoice: "af_heart"
  property string currentVoiceName: "Heart"
  property string currentRate: "+0%"
  property string lastSnippet: ""

  readonly property var voices: [
    { id: "af_heart", name: "Heart", desc: "Warm, Expressive Studio (US F)" },
    { id: "af_bella", name: "Bella", desc: "Natural, Conversational (US F)" },
    { id: "am_michael", name: "Michael", desc: "Deep, Podcast Host (US M)" },
    { id: "am_adam", name: "Adam", desc: "Clear, Engaging Narrator (US M)" },
    { id: "bf_emma", name: "Emma", desc: "Refined, Studio Narrator (UK F)" },
    { id: "bm_george", name: "George", desc: "Warm, Classic Audiobook (UK M)" }
  ]

  readonly property var rates: [
    { id: "-15%", label: "0.85x" },
    { id: "+0%", label: "1.0x" },
    { id: "+15%", label: "1.15x" },
    { id: "+30%", label: "1.3x" }
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
        if (data.rate) root.currentRate = String(data.rate)
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

  function selectRate(rateStr) {
    root.currentRate = rateStr
    Util.execArgv([root.cliPath, "set-rate", rateStr])
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
    contentWidth: panel.fittedContentWidth(Style.space(350))
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
          detail: root.isPlaying ? (root.isPaused ? "PAUSED" : "LIVE") : root.neutralizeMarkup(root.currentRate)
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
            text: "Read Selected Text"
            bordered: true
            selected: root.isPlaying && !root.isPaused
            onClicked: root.triggerRead()
          }

          Button {
            text: root.isPaused ? "Resume" : "Pause"
            bordered: true
            selected: root.isPaused
            enabled: root.isPlaying
            onClicked: root.triggerPause()
          }

          Button {
            text: "Stop"
            bordered: true
            enabled: root.isPlaying
            onClicked: root.triggerStop()
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        PanelSectionHeader {
          text: "REALISTIC VOICES"
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
                width: parent.width - sampleBtn.implicitWidth - Style.space(6)
                text: modelData.name + " — " + modelData.desc
                bordered: true
                selected: root.currentVoice === modelData.id
                onClicked: root.selectVoice(modelData.id, modelData.name)
              }

              Button {
                id: sampleBtn
                text: "Sample"
                bordered: true
                onClicked: root.previewVoice(modelData.id)
              }
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        PanelSectionHeader {
          text: "SPEECH SPEED"
          foreground: Commons.Color.foreground
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.rates
            delegate: Button {
              text: modelData.label
              bordered: true
              selected: root.currentRate === modelData.id
              onClicked: root.selectRate(modelData.id)
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
          color: Qt.darker(Commons.Color.foreground, 1.25)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          text: "Last read: \"" + root.lastSnippet + "\""
        }
      }
    }
  }
}
