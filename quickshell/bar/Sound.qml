import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls

import "../utils/"

Rectangle {
    implicitHeight: parent.height
    implicitWidth: soundLayout.implicitWidth

    property bool mute: false
    property string soundPercentage: ""

    color: "transparent"

    RowLayout {
        id: soundLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            id: icon
            font.pixelSize: 12
            font.family: "Rubik"
            font.weight: Font.Medium
            color: mute ? ColorLoader.getColor("desactive") : ColorLoader.getColor("fg")
            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 4
        }

    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: soundWindow.visible = true
        onExited: soundWindow.visible = false
    }

    Window {
        id: soundWindow
        visible: false
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"

        x: icon.mapToGlobal(0, 0).x + (icon.width - tooltip.width) / 2
        y: parent.mapToGlobal(0, 0).y + parent.height + 5

        width: popupText.implicitWidth + 20
        height: popupText.implicitHeight + 16

        Rectangle {
            id: tooltip
            anchors.fill: parent
            color: ColorLoader.getColor("bg")
            border.color: ColorLoader.getColor("fg")
            border.width: 1
            radius: 6
        }

        Text {
            id: popupText
            anchors.centerIn: parent
            text: soundPercentage
            color: ColorLoader.getColor("fg")
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Process {
        id: soundIcon
        command: ["/home/shui/.config/quickshell/script/sound.sh", "icon"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                icon.text = this.text.trim()

                mute = (icon.text === "󰝟")
            }
        }
    }

    Process {
        id: soundNum
        command: ["/home/shui/.config/quickshell/script/sound.sh", "num"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var percentageStr = this.text.trim()
                soundPercentage = percentageStr + "%"
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            soundIcon.running = true
            soundNum.running = true
        }
    }
}
