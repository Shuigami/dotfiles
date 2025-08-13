import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls


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
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2
            font.family: "Rubik"
            font.weight: Font.Medium
            color: mute ? "#263b37" : "#77977e"
            Layout.alignment: Qt.AlignVCenter
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
            text: lightPercentage
            color: "#77977e"
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
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

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            lightIcon.running = true
            lightNum.running = true
        }
    }
}
