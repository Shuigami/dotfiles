pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import QtQml

Singleton {
    id: colorLoader
    property var colors: ({})
    property int revision: 0

    function getColor(name) {
        var _ = colors;
        return (colors && colors[name]) ? colors[name] : "transparent";
    }

    function reloadColors() {
        var t = ThemeLoader.getTheme();
        if (!t || !t.path) {
            return;
        }
        loadColors.command = ["cat", t.path + "/colors.txt"];
        loadColors.running = true;
    }

    Process {
        id: loadColors
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text || "";
                var lines = text.trim().length ? text.trim().split("\n") : [];
                var newColors = ({});
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":");
                    if (parts.length === 2) {
                        newColors[parts[0].trim()] = parts[1].trim();
                    }
                }
                colorLoader.colors = newColors;
                colorLoader.revision++;
            }
        }
    }

    Component.onCompleted: reloadColors()

    Connections {
        target: ThemeLoader
        function onCurrentThemeChanged() {
            colorLoader.reloadColors();
        }
    }
}