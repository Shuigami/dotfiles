import QtQuick 2.15
import QtQuick.Layouts 1.15
import Quickshell.Io

import "../utils/"

Rectangle {
    property string workspaceText: ""
    property bool active: false
    property bool occupied: false
    property bool isMusic: false

    color: "transparent"

    implicitHeight: parent.height
    implicitWidth: 30

    radius: 6

    Text {
        id: workspaceTxt

        text: parent.isMusic ? "\uf025" : parent.active ? "" : parent.occupied ? "" : ""

        color: parent.isMusic ? parent.active || parent.occupied ? ColorLoader.getColor("fg") : ColorLoader.getColor("desactive") : ColorLoader.getColor("fg")
        font.pixelSize: 14
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2
    }    
}
