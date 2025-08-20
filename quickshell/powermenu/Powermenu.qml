import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../utils"

FloatingWindow {
    id: powermenuWindow
    implicitWidth: 1000
    implicitHeight: 500
    visible: false
    
    color: "transparent"

    title: "powermenu"

    Rectangle {
        anchors.fill: parent
        anchors {
            leftMargin: 8
            topMargin: 8
            rightMargin: 8
            bottomMargin: 8
        }
        radius: 10
        color: ColorLoader.getColor("opacity-clear") + ColorLoader.getColor("bg").substring(1)

        Shortcut {
            sequence: "Escape"
            onActivated: {
                powermenuToggleProcess.running = true;
            }
        }
    }
    
    Process {
        id: powermenuStatusProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "powermenu-status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "true") {
                    powermenuWindow.visible = true;
                } else {
                    powermenuWindow.visible = false;
                }
            }
        }
    }

    Process {
        id: powermenuToggleProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "powermenu-toggle"]
        running: false
    }


    Connections {
        target: root
        onTick: {
            powermenuStatusProcess.running = true;
        }
    }
}
