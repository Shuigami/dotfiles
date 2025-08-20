import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls

import "../utils/"

Rectangle {
    implicitHeight: parent.height
    implicitWidth: lightLayout.implicitWidth

    property bool mute: false
    property string lightPercentage: ""

    color: "transparent"

    RowLayout {
        id: lightLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            id: icon
            font.pixelSize: 16
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

        onEntered: lightWindow.visible = true
        onExited: lightWindow.visible = false
    }

    Window {
        id: lightWindow
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
            text: lightPercentage
            color: ColorLoader.getColor("fg")
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Process {
        id: lightProcess
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim()
                if (line.indexOf("backlight") !== -1) {
                    lightNum.running = true
                    lightIcon.running = true
                }
            }
        }
    }

    Process {
        id: lightIcon
        command: ["/home/shui/.config/quickshell/script/light.sh", "icon"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                icon.text = this.text.trim()
            }
        }
    }

    Process {
        id: lightNum
        command: ["/home/shui/.config/quickshell/script/light.sh", "num"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var percentageStr = this.text.trim()
                lightPercentage = percentageStr + "%"
            }
        }
    }
}
