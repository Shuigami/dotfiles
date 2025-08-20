import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls

import "../utils/"

Rectangle {
    implicitHeight: parent.height
    implicitWidth: bluetoothLayout.implicitWidth

    property bool off: false
    property bool connected: false
    property string bluetoothName: ""

    color: "transparent"

    RowLayout {
        id: bluetoothLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            id: icon
            font.pixelSize: 16
            font.family: "Rubik"
            font.weight: Font.Medium
            color: off ? ColorLoader.getColor("desactive") : connected ? ColorLoader.getColor("fg") : ColorLoader.getColor("desactive")
            Layout.alignment: Qt.AlignVCenter
            Layout.topMargin: 4
        }

    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: if (connected) bluetoothWindow.visible = true
        onExited: bluetoothWindow.visible = false
        onClicked: bluetoothToggle.running = true
    }

    Window {
        id: bluetoothWindow
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
            text: bluetoothName
            color: ColorLoader.getColor("fg")
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Process {
        id: bluetoothProcess
        command: ["hcidump", "-X"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim()
                console.log(line)
                console.log(line.startsWith("> HCI Event"))
                if (line.startsWith("> HCI Event")) {
                    bluetoothIcon.running = true
                    bluetoothStatus.running = true
                }
            }
        }
    }

    Process {
        id: bluetoothIcon
        command: ["/home/shui/.config/quickshell/script/bluetooth.sh", "icon"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: icon.text = this.text.trim()
        }
    }

    Process {
        id: bluetoothToggle
        command: ["/home/shui/.config/quickshell/script/bluetooth.sh", "toggle"]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                if (lines[lines.length - 1] === "off") bluetoothWindow.visible = false
            }
        }
    }

    Process {
        id: bluetoothStatus
        command: ["/home/shui/.config/quickshell/script/bluetooth.sh", "status"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let status = this.text.trim()
                off = (status === "off")
                connected = (status === "connected")

                if (connected) {
                    bluetoothNameProc.running = true
                }
            }
        }
    }

    Process {
        id: bluetoothNameProc
        command: ["/home/shui/.config/quickshell/script/bluetooth.sh", "name"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: bluetoothName = this.text.trim()
        }
    }
}
