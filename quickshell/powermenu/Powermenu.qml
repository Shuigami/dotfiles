import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../utils"

FloatingWindow {
    id: powermenuWindow
    implicitWidth: 1250
    implicitHeight: 300
    visible: false

    color: "transparent"
    title: "powermenu"

    property int selectedCell: -1
    property var options: [
        { icon: "assets/sleep.png", name: "Sleep", offsetX: 2, offsetY: 0, scale: 0.84, command: "amixer set Master mute && systemctl suspend && slock" },
        { icon: "assets/refresh.png", name: "Restart", offsetX: 0, offsetY: -3, scale: 0.95, command: "systemctl reboot" },
        { icon: "assets/power.png", name: "Turn Off", offsetX: 0, offsetY: -1, scale: 0.95, command: "systemctl poweroff" },
        { icon: "assets/logout.png", name: "Log Out", offsetX: 9, offsetY: 3, scale: 1.0, command: "bspc quit" },
        { icon: "assets/padlock.png", name: "Lock", offsetX: 0, offsetY: -3, scale: 0.9, command: "slock" },
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

                Image {
                    id: iconImage
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: options[index].offsetX
                    anchors.verticalCenterOffset: options[index].offsetY
                    source: options[index].icon
                    width: 80 * options[index].scale
                    height: 80 * options[index].scale
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                ColorOverlay {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: options[index].offsetX
                    anchors.verticalCenterOffset: options[index].offsetY
                    width: 80 * options[index].scale
                    height: 80 * options[index].scale
                    source: iconImage
                    color: isSelected ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
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
                    powermenuWindow.selectedCell = -1;
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
