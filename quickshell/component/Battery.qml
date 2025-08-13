import QtQuick
import QtQuick.Layouts
import Quickshell.Io


Rectangle {
    implicitHeight: parent.height
    implicitWidth: batteryLayout.implicitWidth

    property string chargingIcon: "󱐋"
    property bool charging: false
    property bool low: false
    property bool superlow: false

    color: "transparent"

    RowLayout {
        id: batteryLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            id: icon
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            font.family: "Rubik"
            font.weight: Font.Medium
            color: low ? superlow ? "#ff5e5e" : "#e6e682" : "#77977e"
            Layout.alignment: Qt.AlignVCenter
        }

    }


    Process {
        id: batteryIcon
        command: ["/home/shui/.config/quickshell/script/battery.sh", "icon"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: icon.text = charging ? chargingIcon : this.text.trim()
        }
    }

    Process {
        id: batteryNum
        command: ["/home/shui/.config/quickshell/script/battery.sh", "num"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                low = parseInt(this.text.trim()) < 20
                superlow = parseInt(this.text.trim()) < 10
            }
        }
    }

    Process {
        id: batteryStatus
        command: ["/home/shui/.config/quickshell/script/battery.sh", "charging"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: charging = this.text == "Charging"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            batteryIcon.running = true
            batteryNum.running = true
            batteryStatus.running = true
        }
    }
}