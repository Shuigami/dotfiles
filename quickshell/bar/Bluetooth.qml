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
        acceptedButtons: Qt.AllButtons;

        onEntered: if (connected && !bluetoothWidget.visible) bluetoothWindow.visible = true
        onExited: bluetoothWindow.visible = false
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                bluetoothWidget.visible = !bluetoothWidget.visible
            }
        }
    }

    BluetoothWidget {
        id: bluetoothWidget
    }

    Process {
        id: bluetoothProcess
        command: ["hcidump", "-X"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                var line = data.trim()
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
}
