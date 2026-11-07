import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "raqune.loot-pad"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property string notePath: Quickshell.env("HOME") + "/.local/state/omarchy/ctf/loot.json"
  property string userFlag: ""
  property string rootFlag: ""
  property string creds: ""

  FileView {
    id: lootFile
    path: root.notePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var data = JSON.parse(text())
        root.userFlag = data.userFlag || ""
        root.rootFlag = data.rootFlag || ""
        root.creds = data.creds || ""
      } catch(e) {}
    }
    onFileChanged: reload()
  }

  function saveLoot(u, r, c) {
    root.userFlag = u
    root.rootFlag = r
    root.creds = c
    lootFile.setText(JSON.stringify({ userFlag: u, rootFlag: r, creds: c }, null, 2) + "\n")
  }

  function copyStr(str, label) {
    if (!str) return
    Util.execArgv(["sh", "-c", "printf '%s' \"$1\" | wl-copy && omarchy-notification-send 'Loot Pad' \"Copied $2\"", "copy", str, label])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    slotSize: Style.bar.statusSlot
    tooltipText: "CTF Loot & Flags Scratchpad"
    iconComponent: Component {
      Image {
        cache: false
        source: Qt.resolvedUrl("loot-pad-cad.svg")
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
          title: "Target Loot Pad"
          meta: "FLAGS & CREDENTIALS"
          detail: (root.userFlag !== "" ? "U " : "") + (root.rootFlag !== "" ? "R" : "")
          foreground: Commons.Color.foreground
          iconComponent: Component {
            Image {
              width: Style.space(24)
              height: Style.space(24)
              cache: false
              source: Qt.resolvedUrl("loot-pad-cad.svg")
              fillMode: Image.PreserveAspectFit
            }
          }
        }

        PanelSeparator { foreground: Commons.Color.foreground }

        Row {
          width: parent.width
          spacing: Style.space(6)
          TextField {
            id: uInput
            width: parent.width - uCopy.implicitWidth - Style.space(6)
            text: root.userFlag
            placeholderText: "User Flag (user.txt)"
            onEditingFinished: root.saveLoot(text, rInput.text, cInput.text)
          }
          Button {
            id: uCopy
            text: "Copy"
            bordered: true
            onClicked: {
              root.saveLoot(uInput.text, rInput.text, cInput.text)
              root.copyStr(uInput.text, "User Flag")
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(6)
          TextField {
            id: rInput
            width: parent.width - rCopy.implicitWidth - Style.space(6)
            text: root.rootFlag
            placeholderText: "Root Flag (root.txt)"
            onEditingFinished: root.saveLoot(uInput.text, text, cInput.text)
          }
          Button {
            id: rCopy
            text: "Copy"
            bordered: true
            onClicked: {
              root.saveLoot(uInput.text, rInput.text, cInput.text)
              root.copyStr(rInput.text, "Root Flag")
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(6)
          TextField {
            id: cInput
            width: parent.width - cCopy.implicitWidth - Style.space(6)
            text: root.creds
            placeholderText: "Creds / Notes (e.g. admin:pass)"
            onEditingFinished: root.saveLoot(uInput.text, rInput.text, text)
          }
          Button {
            id: cCopy
            text: "Copy"
            bordered: true
            onClicked: {
              root.saveLoot(uInput.text, rInput.text, cInput.text)
              root.copyStr(cInput.text, "Credentials")
            }
          }
        }
      }
    }
  }
}
