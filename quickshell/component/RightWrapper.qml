import QtQuick
import QtQuick.Layouts

Rectangle {
    anchors {
        right: parent.right
    }

    implicitHeight: parent.height
    implicitWidth: 800

    color: "transparent"

    anchors.rightMargin: 18

    RowLayout {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        layoutDirection: Qt.RightToLeft

        spacing: 20

        Battery {}
        Bluetooth {}
    }
}