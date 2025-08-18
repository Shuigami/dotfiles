pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: colorLoader
    property var colors: ({})

    function getColor(name) {
        if (colors[name]) {
            return colors[name];
        }

        if (loadColors.running) {
            return "transparent";
        }

        return colors[name] || "transparent";
    }

    Process {
        id: loadColors
        command: ["cat", "/home/shui/.config/colors/colors.txt"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":");
                    if (parts.length === 2) {
                        colors[parts[0].trim()] = parts[1].trim();
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: loadColors.running = true
    }
}