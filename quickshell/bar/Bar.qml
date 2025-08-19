import QtQuick
import Quickshell

import "../utils"

PanelWindow {
    id: root
    anchors {
        left: true
        top: true
        right: true
    }

    color: "transparent"
    implicitHeight: 50

    Rectangle {
        anchors.fill: parent
        anchors {
            leftMargin: 8
            topMargin: -8
            rightMargin: 8
            bottomMargin: 8
        }
        
        radius: 8
        color: ColorLoader.getColor("opacity-normal") + ColorLoader.getColor("bg").substring(1)
        border.color: ColorLoader.getColor("fg")
        border.width: 2

        Workspaces {}

        Clock {}

        RightWrapper {}
    }
}
