import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls


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
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            font.family: "Rubik"
            font.weight: Font.Medium
            color: off ? "#263b37" : connected ? "#77977e" : "#263b37"
            Layout.alignment: Qt.AlignVCenter
        }

    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: bluetoothWindow.visible = true
        onExited: bluetoothWindow.visible = false
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
            color: "#0b1123"
            border.color: "#77977e"
            border.width: 1
            radius: 6

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: "#000000"
                border.width: 1
                radius: parent.radius
                opacity: 0.3
                z: -1
            }
        }

        Text {
            id: popupText
            anchors.centerIn: parent
            text: bluetoothName
            color: "#77977e"
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
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

    Process {
        id: bluetoothNameProc
        command: ["/home/shui/.config/quickshell/script/bluetooth.sh", "name"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: bluetoothName = this.text.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            bluetoothIcon.running = true
            bluetoothStatus.running = true
        }
    }
}
