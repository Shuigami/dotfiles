import Quickshell
import QtQuick
import QtQuick.Controls
import "../utils"

Rectangle {
    id: leftPartRoot
    property alias filterText: inputField.text
    anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
    }
    implicitWidth: parent.width / 2
    radius: 10
    color: "transparent"

    TextField {
        id: inputField
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 20
        }

        height: 50

        placeholderText: "Search..."
        placeholderTextColor: ColorLoader.getColor("fg")
        font.pixelSize: 16
        font.family: "Rubik"
        font.weight: Font.Medium
        padding: 16

        color: ColorLoader.getColor("fg")
            
        background: Rectangle {
            color: ColorLoader.getColor("bg")
            border.color: ColorLoader.getColor("fg")
            border.width: 2
            radius: 10
        }
            
        focus: true
    }
}