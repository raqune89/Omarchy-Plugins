import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "raqune.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: wsBtn
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        labelVisible: false
        keepSpace: true
        hasVisualContent: true
        horizontalMargin: 2
        verticalPadding: 2
        fixedWidth: root.vertical ? root.barSize : 30
        fixedHeight: root.barSize
        tooltipText: "Sector " + (modelData < 10 ? "0" + modelData : modelData) + (focused ? " [LOCKED]" : (occupied ? " [ACTIVE]" : " [STANDBY]"))
        onPressed: function() { root.focusWorkspace(modelData) }

        Rectangle {
          anchors.centerIn: parent
          width: 24
          height: 18
          color: focused ? "#142826" : (occupied ? "#0e1c18" : "transparent")
          border.width: 1
          border.color: focused ? "#8a9a5b" : (occupied ? "#4d735f" : "#2a3d3b")

          Rectangle { width: 3; height: 1; color: focused ? "#78b86e" : (occupied ? "#56856e" : "#3b5450"); anchors.top: parent.top; anchors.left: parent.left }
          Rectangle { width: 1; height: 3; color: focused ? "#78b86e" : (occupied ? "#56856e" : "#3b5450"); anchors.top: parent.top; anchors.left: parent.left }
          Rectangle { width: 3; height: 1; color: focused ? "#78b86e" : (occupied ? "#56856e" : "#3b5450"); anchors.bottom: parent.bottom; anchors.right: parent.right }
          Rectangle { width: 1; height: 3; color: focused ? "#78b86e" : (occupied ? "#56856e" : "#3b5450"); anchors.bottom: parent.bottom; anchors.right: parent.right }

          Text {
            anchors.centerIn: parent
            text: (modelData === 10 ? "0" : String(modelData))
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.bold: focused
            color: focused ? "#8a9a5b" : (occupied ? "#78b86e" : "#627d78")
          }
        }
      }
    }
  }
}
