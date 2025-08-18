import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../utils"

FloatingWindow {
    id: myWindow
    implicitWidth: 1000
    implicitHeight: 500
    visible: false
    
    color: "transparent"

    title: qsTr("dmenu")

    Rectangle {
        anchors.fill: parent
        anchors {
            leftMargin: 8
            topMargin: 8
            rightMargin: 8
            bottomMargin: 8
        }
        radius: 10
        color: ColorLoader.getColor("transparency") + ColorLoader.getColor("bg").substring(1)

    LeftPart { id: leftPart }
    RightPart {
        id: rightPart
        filterText: leftPart.filterText
        onLaunched: {
            dmenuToggleProcess.running = true;
            clearFilterTimer.restart();
        }
    }

        Timer {
            id: clearFilterTimer
            interval: 500
            repeat: false
            onTriggered: leftPart.filterText = ""
        }

        Shortcut {
            sequence: "Escape"
            onActivated: {
                dmenuToggleProcess.running = true;
            }
        }

        Shortcut {
            sequence: "Up"
            context: Qt.ApplicationShortcut
            onActivated: rightPart.moveSelection(-1)
        }
        Shortcut {
            sequence: "Down"
            context: Qt.ApplicationShortcut
            onActivated: rightPart.moveSelection(1)
        }
        Shortcut {
            sequence: "Enter"
            context: Qt.ApplicationShortcut
            onActivated: rightPart.launchCurrent()
        }

        Shortcut {
            sequence: "Return"
            context: Qt.ApplicationShortcut
            onActivated: rightPart.launchCurrent()
        }
    }
    
    Process {
        id: dmenuStatusProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "true") {
                    myWindow.visible = true;
                } else {
                    myWindow.visible = false;
                }
            }
        }
    }

    Process {
        id: dmenuToggleProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "toggle"]
        running: false
    }

    
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            dmenuStatusProcess.running = true;
        }
    }
}