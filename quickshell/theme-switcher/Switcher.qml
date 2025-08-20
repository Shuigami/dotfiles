import Quickshell
import QtQuick.Layouts
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../utils"

FloatingWindow {
    id: themeSwitcherWindow
    implicitWidth: 1000
    implicitHeight: 300
    title: "theme-switcher"
    color: "transparent"

    visible: false

    property var themes: ThemeLoader.getThemes()

    Rectangle {
        id: frameRect
        anchors.fill: parent
        radius: 10
        // Compose the background color once to reuse in gradients
        property color bgColor: ColorLoader.getColor("opacity-normal") + ColorLoader.getColor("bg").substring(1)
        color: bgColor
        border.color: ColorLoader.getColor("fg")
        border.width: 2

        ListView {
            id: themeList
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 12
            clip: true
            highlightMoveDuration: 80
            orientation: ListView.Horizontal
            model: themes
            ScrollBar.horizontal: ScrollBar { }

            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - (currentItem ? currentItem.width / 2 : 125)
            preferredHighlightEnd: width / 2 + (currentItem ? currentItem.width / 2 : 125)
            snapMode: ListView.SnapToItem

            Component.onCompleted: {
                const currentTheme = ThemeLoader.getTheme().name
                const m = themeList.model
                const len = m && m.length !== undefined ? m.length : themeList.count
                for (var i = 0; i < len; i++) {
                    const item = m && m.length !== undefined ? m[i] : null
                    const name = item ? item.name : null
                    if (name === currentTheme) {
                        themeList.currentIndex = i
                        themeList.positionViewAtIndex(i, ListView.Center)
                        break
                    }
                }
            }

            LinearGradient {
                anchors { left: themeList.left; top: themeList.top; bottom: themeList.bottom }
                width: 100
                z: 10
                visible: themeList.contentX > 0
                start: Qt.point(0, 0)
                end: Qt.point(width, 0)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: frameRect.bgColor }
                    GradientStop { position: 1.0; color: Qt.rgba(frameRect.bgColor.r, frameRect.bgColor.g, frameRect.bgColor.b, 0) }
                }
            }

            LinearGradient {
                anchors { right: themeList.right; top: themeList.top; bottom: themeList.bottom }
                width: 100
                z: 10
                visible: themeList.contentX + themeList.width < themeList.contentWidth - 1
                start: Qt.point(0, 0)
                end: Qt.point(width, 0)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(frameRect.bgColor.r, frameRect.bgColor.g, frameRect.bgColor.b, 0) }
                    GradientStop { position: 1.0; color: frameRect.bgColor }
                }
            }

            delegate: Item {
                width: 250
                height: parent.height

                property var isSelected: ThemeLoader.getTheme()?.name == modelData.name

                onIsSelectedChanged: {
                    if (isSelected) {
                        themeList.currentIndex = index
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: isSelected ? ColorLoader.getColor("opacity-normal") + ColorLoader.getColor("fg").substring(1) : "transparent"
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 12
                    fillMode: Image.PreserveAspectFit
                    source: modelData.path + "/wp.jpg"
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = modelData.path + "/wp.png"
                        }
                    }
                }

                Text {
                    width: parent.width
                    height: 44
                    anchors.leftMargin: 40
                    text: modelData.name
                    color: isSelected ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                    font.pixelSize: 16
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
        sequence: "Left"
        onActivated: {
            if (themeList.currentIndex > 0) {
                themeList.currentIndex--;
            } else {
                themeList.currentIndex = themes.length - 1;
            }

            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Center);
            ThemeLoader.setTheme(themes[themeList.currentIndex].name);
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (themeList.currentIndex < themeList.count - 1) {
                themeList.currentIndex++;
            } else {
                themeList.currentIndex = 0;
            }

            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Center);
            ThemeLoader.setTheme(themes[themeList.currentIndex].name);
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            themeToggleProcess.running = true;
        }
    }

    Process {
        id: themeStatusProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "theme-switcher-status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "true") {
                    themeSwitcherWindow.visible = true;
                } else {
                    themeSwitcherWindow.visible = false;
                }
            }
        }
    }

    Process {
        id: themeToggleProcess
        command: ["node", "/home/shui/.config/quickshell/script/boolean.js", "theme-switcher-toggle"]
        running: false
    }


    Connections {
        target: root
        onTick: {
            themeStatusProcess.running = true;
        }
    }
}
