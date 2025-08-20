import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../utils"

FloatingWindow {
    id: powermenuWindow
    implicitWidth: 1000
    implicitHeight: 300
    visible: false

    color: "transparent"
    title: "powermenu"

    property int selectedCell: -1
    property var options: [
        { icon: "󰐥", name: "Turn Off", offset: -1, command: "systemctl poweroff" },
        { icon: "󰆷", name: "Restart", offset: -10, command: "systemctl reboot" },
        { icon: "󰤄", name: "Sleep", offset: 0, command: "amixer set Master mute && ~/.config/i3/scripts/lock.sh && systemctl suspend" },
        { icon: "󰗼", name: "Log Out", offset: -5, command: "bspc quit" }
    ]

    Rectangle {
        anchors.fill: parent
        anchors {
            leftMargin: 8
            topMargin: 8
            rightMargin: 8
            bottomMargin: 8
        }
        radius: 10
        color: "transparent"

        ListView {
            id: powermenuList
            model: options
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 50
            }

            spacing: 12
            clip: true
            highlightMoveDuration: 80
            orientation: ListView.Horizontal
            ScrollBar.horizontal: ScrollBar { }

            delegate: Item {
                property bool isSelected: powermenuWindow.selectedCell === index

                width: 210
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    color: isSelected ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                    border.color: ColorLoader.getColor("fg")
                    border.width: 2
                    radius: 10
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: options[index].offset
                    text: options[index].icon
                    color: isSelected ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                    font.pixelSize: 80
                    font.family: "Rubik"
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    
    Shortcut {
        sequence: "Escape"
        onActivated: {
            powermenuToggleProcess.running = true;
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (selectedCell === -1 || selectedCell === 0) {
                powermenuWindow.selectedCell = options.length - 1;
            } else {
                powermenuWindow.selectedCell--;
            }
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (selectedCell !== -1) {
                var command = options[selectedCell].command;
                if (command) {
                    powermenuToggleProcess.running = true;
                    powermenuCommandProcess.command = [ "bash", "-c", command ];
                    powermenuCommandProcess.running = true;
                }
            }
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (selectedCell === -1 || selectedCell === options.length - 1) {
                powermenuWindow.selectedCell = 0;
            } else {
                powermenuWindow.selectedCell++;
            }
        }
    }

    Process {
        id: powermenuCommandProcess
        command: ["bash", "-c", ""]
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
        function onTick() {
            powermenuStatusProcess.running = true;
        }
    }
}
