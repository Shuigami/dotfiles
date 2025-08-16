import QtQuick
import Quickshell

import "component"

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
        color: ColorLoader.getColor("bg")
        border.color: ColorLoader.getColor("fg")
        border.width: 2

        opacity: 0.9

        Workspaces {}

        Clock {}

        RightWrapper {}
    }
}
