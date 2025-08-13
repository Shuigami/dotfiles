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
        anchors.margins: 8
        
        radius: 8
        color: "#0b1123"
        // color: "#0b11ff"
        border.color: "#77977e"
        border.width: 2

        opacity: 0.9

        Workspaces {}

        Clock {}
    }
}
