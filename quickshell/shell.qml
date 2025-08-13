import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "widget"

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

        opacity: 0.9

        Workspaces {}
    }
}
