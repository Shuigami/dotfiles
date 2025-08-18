import QtQuick
import Quickshell.Io

import "../utils/"

Rectangle {
    implicitHeight: parent.height
    implicitWidth: 30
    anchors.horizontalCenter: parent.horizontalCenter

    color: "transparent"

    Text {
        id: clock
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2

        font.pixelSize: 16
        font.family: "Rubik"
        font.weight: Font.Medium

        color: ColorLoader.getColor("fg")

        Process {
            id: dateProc
            command: ["date", "+%H:%M"]
            running: true

            stdout: StdioCollector {
                onStreamFinished: clock.text = this.text.trim()
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: dateProc.running = true
        }
    }
}