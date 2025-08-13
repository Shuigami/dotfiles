import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: row
    anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
    }
    anchors.leftMargin: 10

    Process {
        id: workspace
        running: true
        command: [ "bspc", "query", "-D", "--names" ]

        stdout: StdioCollector {
            onStreamFinished: {
                row.children.forEach(function(c) { c.destroy(); })

                let lines = this.text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    Qt.createComponent("Workspace.qml").createObject(row, {
                        workspaceText: lines[i]
                    })
                }
            }
        }
    }

    Process {
        id: activeWorkspace
        running: true
        command: [ "bspc", "query", "-D", "-d", "focused", "--names" ]

        stdout: StdioCollector {
            onStreamFinished: {
                let active = this.text.trim()
                for (let i = 0; i < row.children.length; i++) {
                    let child = row.children[i]
                    child.active = (child.workspaceText === active)
                }
            }
        }
    }

    Process {
        id: occupiedWorkspace
        running: true
        command: [ "bspc", "query", "-D", "-d", ".occupied", "--names" ]

        stdout: StdioCollector {
            onStreamFinished: {
                let occupied = this.text.trim().split("\n")
                for (let i = 0; i < row.children.length; i++) {
                    let child = row.children[i]
                    child.occupied = occupied.includes(child.workspaceText)
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            activeWorkspace.running = true
            occupiedWorkspace.running = true
        }
    }
}