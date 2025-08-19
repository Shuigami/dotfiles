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
            console.log("Current theme:", currentTheme);
            return themes[currentTheme];
        } else {
            console.warn("Theme not found:", currentTheme);
        }
    }

    function getThemes() {
        if (loadThemes.running) {
            return [];
        }

        var names = Object.keys(themes);
        if (names.length === 0) {
            console.warn("No themes available");
        } else {
            console.log("Available themes:", names);
        }
        return Object.values(themes);
    }

    function setTheme(name) {
        if (themes[name]) {
            currentTheme = name;
            setThemeProcess.running = true;
        } else {
            console.warn("Theme not found:", name);
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
                    console.log("Found theme:", lines[i].trim());
                    themes[lines[i].trim()] = {
                        name: lines[i].trim(),
                        path: "/home/shui/.config/themes/" + lines[i].trim()
                    };
                }

                getDefaultTheme.running = true;
                if (Object.keys(themes).length === 0) {
                    console.warn("No themes found in /home/shui/.config/themes");
                } else {
                    console.log("Themes loaded successfully:", Object.keys(themes));
                }
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
