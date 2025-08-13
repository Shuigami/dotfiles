import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls


Rectangle {
    implicitHeight: parent.height
    implicitWidth: batteryLayout.implicitWidth

    property string chargingIcon: "󱐋"
    property bool charging: false
    property bool low: false
    property bool superlow: false
    property string batteryPercentage: ""

    color: "transparent"

    RowLayout {
        id: batteryLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            id: icon
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            font.family: "Rubik"
            font.weight: Font.Medium
            color: low ? superlow ? "#ff5e5e" : "#e6e682" : "#77977e"
            Layout.alignment: Qt.AlignVCenter
        }

    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: batteryWindow.visible = true
        onExited: batteryWindow.visible = false
    }

    Window {
        id: batteryWindow
        visible: false
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"

        x: parent.mapToGlobal(0, 0).x + parent.width / 2 - width / 2
        y: parent.mapToGlobal(0, 0).y + parent.height + 5

        width: popupText.implicitWidth + 20
        height: popupText.implicitHeight + 16

        Rectangle {
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
            text: batteryPercentage
            color: "#77977e"
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Process {
        id: batteryIcon
        command: ["/home/shui/.config/quickshell/script/battery.sh", "icon"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: icon.text = charging ? chargingIcon : this.text.trim()
        }
    }

    Process {
        id: batteryNum
        command: ["/home/shui/.config/quickshell/script/battery.sh", "num"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var percentageStr = this.text.trim()
                batteryPercentage = percentageStr + "%"
                var percentageInt = parseInt(percentageStr)
                low = percentageInt < 20
                superlow = percentageInt < 10
            }
        }
    }

    Process {
        id: batteryStatus
        command: ["/home/shui/.config/quickshell/script/battery.sh", "charging"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: charging = this.text == "Charging"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batteryIcon.running = true
            batteryNum.running = true
            batteryStatus.running = true
        }
    }
}