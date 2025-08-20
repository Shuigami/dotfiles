import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import "../utils"

Rectangle {
    implicitHeight: parent.height
    implicitWidth: wifiLayout.implicitWidth

    color: "transparent"

    property string wifiName: ""
    property string wifiIconSrc: ""
    property int iconSize: 20
    property color wifiColor: ColorLoader.getColor("fg")

    RowLayout {
        id: wifiLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5


        Item {
            id: wifiIconBox
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize
            width: iconSize
            height: iconSize

            Image {
                id: wifiIconImg
                anchors.fill: parent
                source: wifiIconSrc
                visible: false
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                sourceSize.width: iconSize
                sourceSize.height: iconSize
            }

            ColorOverlay {
                anchors.fill: wifiIconImg
                source: wifiIconImg
                color: wifiColor
            }
        }


    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: wifiWindow.visible = true
        onExited: wifiWindow.visible = false
    }

    Window {
        id: wifiWindow
        visible: false
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"

        x: wifiIconBox.mapToGlobal(0, 0).x + (wifiIconBox.width - tooltip.width) / 2
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
            text: wifiName
            color: ColorLoader.getColor("fg")
            font.family: "Rubik"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Process {
        id: wifiProcess
        command: ["iw", "event"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                wifiNameProcess.running = true
                wifiIcon.running = true
            }
        }
    }

    Process {
        id: wifiIcon
        command: ["/home/shui/.config/quickshell/script/wifi.sh", "icon"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                wifiIconSrc = `file:///home/shui/.config/quickshell/bar/assets/${this.text.trim()}.png`
            }
        }
    }

    Process {
        id: wifiNameProcess
        command: ["/home/shui/.config/quickshell/script/wifi.sh", "name"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var nameStr = this.text.trim()
                wifiName = nameStr
            }
        }
    }
}
