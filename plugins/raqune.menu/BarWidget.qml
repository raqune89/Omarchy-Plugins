import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "raqune.menu"

  implicitWidth: 34
  implicitHeight: root.bar ? root.bar.barSize : 32

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    keepSpace: true
    hasVisualContent: true
    fixedWidth: 34
    horizontalMargin: 4
    tooltipText: "Arma Reforger Tactical Menu // [REF-SYS]"
    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }

    Image {
      anchors.centerIn: parent
      width: 22
      height: 22
      cache: false
        source: Qt.resolvedUrl("menu-tactical.svg")
      sourceSize: Qt.size(44, 44)
      fillMode: Image.PreserveAspectFit
      smooth: true
    }
  }
}
