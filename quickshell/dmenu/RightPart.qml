import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

import "../utils"

Rectangle {
    anchors {
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }
    implicitWidth: parent.width / 2
    radius: 10
    color: ColorLoader.getColor("bg")

    property var apps: []
    property string filterText: ""
    property var filteredApps: []

    property int selectedIndex: 0

    function clampSelection() {
        if (!filteredApps || filteredApps.length === 0) {
            selectedIndex = -1;
            return;
        }
        if (selectedIndex < 0) selectedIndex = 0;
        if (selectedIndex >= filteredApps.length) selectedIndex = filteredApps.length - 1;
        appList.currentIndex = selectedIndex;
        appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function moveSelection(delta) {
        if (!filteredApps || filteredApps.length === 0) {
            selectedIndex = -1;
            return;
        }
        selectedIndex = Math.max(0, Math.min(filteredApps.length - 1, selectedIndex + delta));
        appList.currentIndex = selectedIndex;
        appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function updateFilter() {
        var t = (filterText || "").toLowerCase();
        if (!t || t.length === 0) {
            filteredApps = apps;
            clampSelection();
            return;
        }
        var out = [];
        for (var i = 0; i < apps.length; i++) {
            var n = (apps[i].name || "").toLowerCase();
            if (n.indexOf(t) !== -1) out.push(apps[i]);
        }
        filteredApps = out;
        selectedIndex = 0;
        clampSelection();
    }

    // Run once to collect application names, exec command, and resolve icon paths from /usr/share
    Process {
        id: loadApps
        command: [
            "bash", "-lc",
            // Returns lines: Name\tExec\tIconPath
            'set -o pipefail; ' +
            'while IFS= read -r -d "" file; do ' +
            '  name=$(grep -m1 "^Name=" "$file" | head -n1 | cut -d= -f2-); ' +
            '  exec=$(grep -m1 "^Exec=" "$file" | head -n1 | cut -d= -f2-); ' +
            '  icon=$(grep -m1 "^Icon=" "$file" | head -n1 | cut -d= -f2-); ' +
            '  icon_path=""; ' +
            '  if [ -n "$icon" ]; then ' +
            '    if [ -f "$icon" ]; then icon_path="$icon"; else ' +
            '      base="${icon%.*}"; ' +
            '      icon_path=$(find /usr/share/icons /usr/share/pixmaps /var/lib/flatpak/exports/share/icons/hicolor/scalable/apps -type f,l \\( ' +
            '        -iname "$base.png" -o -iname "$base.svg" -o -iname "$base.xpm" -o ' +
            '        -iname "$icon.png" -o -iname "$icon.svg" -o -iname "$icon.xpm" \\) -print -quit 2>/dev/null); ' +
            '      if [ -z "$icon_path" ]; then ' +
            '        icon_path="/home/shui/.config/quickshell/dmenu/assets/file.svg"; ' +
            '      fi; ' +
            '    fi; ' +
            '  fi; ' +
            '  printf "%s\\t%s\\t%s\\n" "$name" "$exec" "$icon_path"; ' +
            'done < <(find /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications -type f,l -name "*.desktop" -print0)'
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim();
                var items = [];
                if (out.length > 0) {
                    var lines = out.split("\n");
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split("\t");
                        var name = (parts[0] || "").trim();
                        var exec = (parts[1] || "").trim();
                        var icon = (parts[2] || "").trim();
                        if (name.length > 0) {
                            items.push({ name: name, icon: icon, exec: exec });
                        }
                    }
                    // sort alphabetically by name
                    items.sort(function(a, b) { return a.name.localeCompare(b.name); });
                }
                apps = items;
            }
        }
    }

    onAppsChanged: updateFilter()
    onFilterTextChanged: updateFilter()
    Component.onCompleted: updateFilter()

    // Scrollable list of apps with icons and names
    ListView {
        id: appList
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 12
        }
        clip: true
        spacing: 6
        highlightMoveDuration: 80
        currentIndex: selectedIndex
        model: filteredApps
        ScrollBar.vertical: ScrollBar { }

        delegate: Item {
            width: ListView.view.width
            height: 44

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: index === selectedIndex ? ColorLoader.getColor("opacity-clear") + ColorLoader.getColor("fg").substring(1) : "transparent"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    width: 32; height: 32
                    fillMode: Image.PreserveAspectFit
                    source: modelData.icon && modelData.icon.length > 0 ? "file:" + modelData.icon : ""
                    visible: modelData.icon && modelData.icon.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: "transparent"
                    border.color: ColorLoader.getColor("fg")
                    visible: !(modelData.icon && modelData.icon.length > 0)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    height: parent.height
                    anchors.leftMargin: 40
                    text: modelData.name
                    color: ColorLoader.getColor("fg")
                    font.pixelSize: 16
                    font.family: "Rubik"
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    width: parent.width - 32 - 12
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: selectedIndex = index
                onClicked: { launchAt(index); }
                onDoubleClicked: { launchAt(index); }
            }
        }
    }

    signal launched()

    function resolveExec(cmd) {
        var cleaned = (cmd || "").replace(/%[fFuUick]/g, "").trim();
        return cleaned;
    }

    function launchAt(idx) {
        if (idx < 0 || idx >= filteredApps.length) return false;
        var item = filteredApps[idx];
        if (!item || !item.exec) return false;
        var execCmd = resolveExec(item.exec);
        if (!execCmd) return false;
        launcher.command = ["sh", "-c", "nohup " + execCmd + " >/dev/null 2>&1 &"];
        launcher.running = true;
        launched();
        return true;
    }

    function launchCurrent() { return launchAt(selectedIndex); }

    Process {
        id: launcher
        running: false
    }

    Process {
        id: dmenuToggleProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "dmenu-toggle"]
        running: false
    }
}