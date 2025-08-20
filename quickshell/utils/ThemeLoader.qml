pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: themeLoader
    property var currentTheme: ""
    property var themes: ({})

    function getTheme() {
        if (themes[currentTheme]) {
            return themes[currentTheme];
        }
    }

    function getThemes() {
        if (loadThemes.running) {
            return [];
        }

        var names = Object.keys(themes);
        return Object.values(themes);
    }

    function setTheme(name) {
        if (themes[name]) {
            currentTheme = name;
            setThemeProcess.running = true;
        }
    }

    Process {
        id: loadThemes
        command: ["ls", "/home/shui/.config/themes"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    themes[lines[i].trim()] = {
                        name: lines[i].trim(),
                        path: "/home/shui/.config/themes/" + lines[i].trim()
                    };
                }

                getDefaultTheme.running = true;
                loadThemes.running = false;
            }
        }
    }

    Process {
        id: getDefaultTheme
        command: ["cat", "/home/shui/.config/quickshell/utils/utils.json"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var json = JSON.parse(this.text);
                if (json.theme) {
                    themeLoader.setTheme(json.theme);
                }
            }
        }
    }

    Process {
        id: setThemeProcess
        command: ["node", "/home/shui/.config/quickshell/script/set-theme.js", themeLoader.currentTheme]
        running: false
    }
}
