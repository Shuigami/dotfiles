import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    property string workspaceText: ""
    property bool active: false
    property bool occupied: false

    color: "transparent"

    implicitHeight: parent.height
    implicitWidth: 30

    radius: 6

    Text {
        id: workspaceTxt

        text: parent.active ? "" : parent.occupied ? "" : ""

        //       

        color: "#d0d0d0"
        font.pixelSize: 14
        anchors.centerIn: parent
    }    
}
