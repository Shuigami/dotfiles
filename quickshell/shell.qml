import QtQuick
import Quickshell
import QtQuick.Controls

import "bar"
import "dmenu"
import "theme-switcher"
import "powermenu"

ShellRoot {
    id: root

    signal tick()

    Bar {}
    Dmenu {}
    Powermenu {}
    Switcher {}

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: root.tick()
    }
}

