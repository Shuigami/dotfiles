import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Controls

import "../utils/"

FloatingWindow {
    id: bluetoothWindow
    title: "bluetooth"
    implicitWidth: 300
    implicitHeight: 400
    visible: false

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: ColorLoader.getColor("opacity-normal") + ColorLoader.getColor("bg").substring(1)
        border.color: ColorLoader.getColor("fg")
        border.width: 1
        radius: 6
    }

    // -----------------------
    // State & Data Model
    // -----------------------
    property bool initialized: false
    property bool scanning: false
    property int scanSeconds: 10
    property int scanRemaining: 0
    property string lastError: ""
    // Guard polling while scanning
    property bool scanPollBusy: false
    property bool scanPollPending: false

    ListModel { id: devicesModel }

    // -----------------------
    // Generic bluetoothctl runner with queueing
    // -----------------------
    function log(msg) { /* console.log(msg) */ }

    // Remove trailing metadata from names (e.g., Class:, Icon:, UUIDs, bracketed tags)
    function sanitizeName(s) {
        if (!s) return s
        let t = String(s)
        // Drop anything after a tab first (bluetoothctl sometimes uses tabs)
        t = t.split("\t")[0]
        // Remove D-Bus object paths (e.g., "/org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX")
        t = t.replace(/\s*\/org\/[^\s]*\s*/g, " ")
        // Remove Media paths and related metadata
        t = t.replace(/\s*Media\s*\/[^\s]*\s*/gi, " ")
        t = t.replace(/\s*Media\s+.*$/gi, "")
        // Remove bracketed tags anywhere (e.g., [LE Audio], [headphones])
        t = t.replace(/\s*\[[^\]]*\]\s*/g, " ")
        // Remove a trailing parenthetical group, often (random), (public)
        t = t.replace(/\s*\([^)]*\)\s*$/g, "")
        // Remove known trailing key:value tokens (expanded list)
        t = t.replace(/\s+(Class|Icon|Appearance|UUIDs?|RSSI|Tx\s*Power|Paired|Connected|Trusted|AddressType|ManufacturerData|Services|ServiceData|Battery|Modalias|Device|Discovering|Discoverable|Pairable|Powered|Name|Alias|Media|Player|Transport|Endpoint):.*$/i, "")
        // Remove common device type indicators and metadata
        t = t.replace(/\s+(LE|BR\/EDR|Classic|Low\s*Energy|Audio|Mouse|Keyboard|Headset|Headphones|Speaker|Controller|Gamepad)(\s|$)/gi, " ")
        // Remove version numbers and model indicators
        t = t.replace(/\s+(v\d+(\.\d+)*|\d+\.\d+|Model\s+\w+|Rev\s+\w+|FW\s+\w+)(\s|$)/gi, " ")
        // Remove noise words and patterns
        t = t.replace(/\s+(device|bluetooth|wireless|corp|corporation|inc|ltd|llc|co|company)(\s|$)/gi, " ")
        // Trim common noisy prefixes and suffixes
        t = t.replace(/^(LE-|BT-|Bluetooth\s+|Device\s+)\s*/i, "")
        t = t.replace(/\s+(Device|Bluetooth)$/i, "")
        // Remove any remaining colons and semicolons at the end
        t = t.replace(/[:;]+\s*$/g, "")
        // Collapse whitespace and strip trailing punctuation
        t = t.replace(/\s+/g, " ").replace(/[-,;:\s]+$/g, "").trim()
        // If result is empty or just punctuation, return the MAC instead
        if (!t || /^[^a-zA-Z0-9]*$/.test(t)) return s
        return t
    }

    function findIndexByMac(mac) {
        for (let i = 0; i < devicesModel.count; i++) {
            if (devicesModel.get(i).mac === mac)
                return i
        }
        return -1
    }

    function upsertDevice(mac, name) {
        let idx = findIndexByMac(mac)
        if (idx === -1) {
            devicesModel.append({
                mac: mac,
                name: name || mac,
                paired: false,
                connected: false,
                trusted: false,
                rssi: "",
            })
        } else {
            if (name && devicesModel.get(idx).name !== name)
                devicesModel.setProperty(idx, "name", name)
        }
    }

    function updateDeviceField(mac, field, value) {
        let idx = findIndexByMac(mac)
        if (idx !== -1) devicesModel.setProperty(idx, field, value)
    }

    // Queue-based executor for bluetoothctl commands to avoid overlapping processes
    Process {
        id: execProcess
        property var queue: []
        property var callback: null
        property string buffer: ""

        stdout: SplitParser { onRead: (data) => execProcess.buffer += data }
        stderr: SplitParser { onRead: (data) => execProcess.buffer += data }

        onRunningChanged: {
            if (!running) {
                let out = execProcess.buffer
                execProcess.buffer = ""
                let cb = execProcess.callback
                execProcess.callback = null
                // continue queue after callback to allow enqueueing within callback
                if (cb) {
                    try { cb(out) } catch (e) { lastError = String(e) }
                }
                maybeStartQueue()
            }
        }
    }

    // Separate process for scanning so it doesn't block the command queue
    Process {
        id: scanProcess
        property string sbuf: ""

        stdout: SplitParser {
            onRead: (data) => {
                scanProcess.sbuf += data
                // parse complete lines; keep partial in buffer
                let lines = scanProcess.sbuf.split(/\r?\n/)
                scanProcess.sbuf = lines.pop() // remainder
                for (let l of lines) parseScanStreamLine(l)
            }
        }
        stderr: SplitParser {
            onRead: (data) => {
                // accumulate and treat stderr similarly; some bluetoothctl versions log to stderr
                scanProcess.sbuf += data
                let lines = scanProcess.sbuf.split(/\r?\n/)
                scanProcess.sbuf = lines.pop()
                for (let l of lines) parseScanStreamLine(l)
            }
        }

        onRunningChanged: {
            if (!running) {
                // finalize any trailing line
                if (scanProcess.sbuf.length > 0) {
                    parseScanStreamLine(scanProcess.sbuf)
                    scanProcess.sbuf = ""
                }
                // scanning session over
                scanning = false
                scanTimer.stop()
                refreshDevices()
            }
        }
    }

    function parseScanStreamLine(l) {
        // Typical lines include:
        //  "Discovery started" / "Discovery stopped"
        //  "[NEW] Device XX:XX:XX:XX:XX:XX Name"
        //  "[CHG] Device XX:XX:XX:XX:XX:XX Name: NewName"
        //  "[CHG] Device XX:XX:XX:XX:XX:XX RSSI: -45"
        if (!l) return
        if (l.startsWith("Device ") || l.includes(" Device ")) {
            // Prefer explicit Name/Alias field when present
            let mName = l.match(/Device\s+([0-9A-Fa-f:]{17}).*?\bName:\s*(.+)$/)
            if (mName) {
                const mac = mName[1]
                const name = sanitizeName(mName[2])
                upsertDevice(mac, name && name.length ? name : mac)
                return
            }
            let mAlias = l.match(/Device\s+([0-9A-Fa-f:]{17}).*?\bAlias:\s*(.+)$/)
            if (mAlias) {
                const mac = mAlias[1]
                const name = sanitizeName(mAlias[2])
                upsertDevice(mac, name && name.length ? name : mac)
                return
            }

            // Generic form: "Device <mac> <maybe-name-or-field>"
            let m = l.match(/Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/) || l.match(/Device\s+([0-9A-Fa-f:]{17})$/)
            if (m) {
                const mac = m[1]
                const rest = (m[2] || "").trim()
                // If the remainder looks like a key:value change (RSSI, UUIDs, etc), don't treat as name
                const looksLikeField = /^((Class|Icon|Appearance|UUIDs?|RSSI|Tx\s*Power|Paired|Connected|Trusted|AddressType|ManufacturerData|Services|ServiceData)\s*:|\(|\[)/i.test(rest)
                const name = looksLikeField ? "" : sanitizeName(rest)
                upsertDevice(mac, name && name.length ? name : mac)
                return
            }

            // Fallback: split approach
            const parts = l.trim().split(/\s+/)
            const idx = parts.indexOf("Device")
            if (idx !== -1 && parts.length > idx + 1) {
                const mac = parts[idx + 1]
                const rest = l.substring(l.indexOf(mac) + mac.length + 1).trim()
                const looksLikeField = /^((Class|Icon|Appearance|UUIDs?|RSSI|Tx\s*Power|Paired|Connected|Trusted|AddressType|ManufacturerData|Services|ServiceData)\s*:|\(|\[)/i.test(rest)
                const name = looksLikeField ? "" : sanitizeName(rest)
                if (/[0-9A-Fa-f:]{17}/.test(mac)) upsertDevice(mac, name || mac)
            }
        }
    }

    function runBtctl(args, cb) {
        execProcess.queue.push({ args: args, cb: cb })
        maybeStartQueue()
    }

    function maybeStartQueue() {
        if (execProcess.running) return
        if (execProcess.queue.length === 0) return
        const item = execProcess.queue.shift()
        execProcess.callback = item.cb || null
        execProcess.command = ["bluetoothctl"].concat(item.args)
        execProcess.buffer = ""
        execProcess.running = true
    }

    // Helper: run list of commands in series
    function runSequence(commands, finalCb) {
        let i = 0
        let lastOut = ""
        function next() {
            if (i >= commands.length) { if (finalCb) finalCb(lastOut); return }
            const args = commands[i++]
            runBtctl(args, function (out) { lastOut = out; next() })
        }
        next()
    }

    // Prepare adapter and agent for pairing/scanning
    function ensureAdapterReady(cb) {
        runSequence([
            ["power", "on"],
            ["agent", "on"],
            ["default-agent"],
            ["pairable", "on"],
        ], function () { if (cb) cb() })
    }

    // -----------------------
    // Data Refresh
    // -----------------------
    function parseDevicesList(output) {
        const lines = output.split(/\r?\n/)
        for (let l of lines) {
            // Matches: Device XX:XX:XX:XX:XX:XX Name with spaces
            if (l.startsWith("Device ")) {
                let parts = l.split(/\s+/)
                if (parts.length >= 3) {
                    let mac = parts[1]
                    let name = l.substring(l.indexOf(mac) + mac.length + 1)
                    upsertDevice(mac, sanitizeName(name.trim()))
                }
            }
        }
    }

    function parseInfo(mac, output) {
        // Update per-device info
        const connectedMatch = output.match(/Connected:\s*(yes|no)/i)
        const pairedMatch = output.match(/Paired:\s*(yes|no)/i)
        const trustedMatch = output.match(/Trusted:\s*(yes|no)/i)
    const nameMatch = output.match(/^Name:\s*(.+)$/mi)
    const aliasMatch = output.match(/^Alias:\s*(.+)$/mi)
        const rssiMatch = output.match(/RSSI:\s*(-?\d+)/)

        if (nameMatch) updateDeviceField(mac, "name", sanitizeName(nameMatch[1].trim()))
        if (aliasMatch) updateDeviceField(mac, "name", sanitizeName(aliasMatch[1].trim()))
        if (connectedMatch) updateDeviceField(mac, "connected", connectedMatch[1].toLowerCase() === "yes")
        if (pairedMatch) updateDeviceField(mac, "paired", pairedMatch[1].toLowerCase() === "yes")
        if (trustedMatch) updateDeviceField(mac, "trusted", trustedMatch[1].toLowerCase() === "yes")
        if (rssiMatch) updateDeviceField(mac, "rssi", rssiMatch[1])
    }

    function rebuildFromOutputs(devOut, pairedOut) {
        const map = {}
        const dlines = devOut.split(/\r?\n/)
        for (let l of dlines) {
            if (!l.startsWith("Device ")) continue
            let parts = l.split(/\s+/)
            if (parts.length < 3) continue
            let mac = parts[1]
            let name = sanitizeName(l.substring(l.indexOf(mac) + mac.length + 1).trim())
            map[mac] = map[mac] || { mac: mac }
            map[mac].name = name || mac
        }
        const plines = pairedOut.split(/\r?\n/)
        for (let l of plines) {
            if (!l.startsWith("Device ")) continue
            let parts = l.split(/\s+/)
            if (parts.length < 3) continue
            let mac = parts[1]
            map[mac] = map[mac] || { mac: mac }
            map[mac].paired = true
            if (!map[mac].name) {
                map[mac].name = sanitizeName(l.substring(l.indexOf(mac) + mac.length + 1).trim())
            }
        }
        devicesModel.clear()
        for (let mac in map) {
            const d = map[mac]
            devicesModel.append({
                mac: d.mac,
                name: d.name || d.mac,
                paired: !!d.paired,
                connected: false,
                trusted: false,
                rssi: "",
            })
        }
        // Avoid flooding info queries while scanning
        if (!scanning) {
            for (let i = 0; i < devicesModel.count; i++) {
                const mac = devicesModel.get(i).mac
                refreshDeviceInfo(mac)
            }
        }
    }

    function refreshDevices() {
        lastError = ""
        runBtctl(["devices"], function (devOut) {
            runBtctl(["paired-devices"], function (pairedOut) {
                rebuildFromOutputs(devOut, pairedOut)
            })
        })
    }

    function pollDevicesRebuild() {
        if (scanPollBusy) { scanPollPending = true; return }
        scanPollBusy = true
        runBtctl(["devices"], function (devOut) {
            runBtctl(["paired-devices"], function (pairedOut) {
                rebuildFromOutputs(devOut, pairedOut)
                scanPollBusy = false
                if (scanPollPending) { scanPollPending = false; pollDevicesRebuild() }
            })
        })
    }

    function refreshDeviceInfo(mac) {
        runBtctl(["info", mac], function (out) { parseInfo(mac, out) })
    }

    // -----------------------
    // Actions
    // -----------------------
    function startScan() {
        if (scanning) return
        ensureAdapterReady(function () {
            devicesModel.clear()
            scanning = true
            scanRemaining = scanSeconds
            // Start dedicated scan process that exits after timeout; parse streaming output
            scanProcess.sbuf = ""
            scanProcess.command = ["bluetoothctl", "--timeout", String(scanSeconds), "scan", "on"]
            scanProcess.running = true
            scanTimer.start()
            // Initial poll to show already known devices
            pollDevicesRebuild()
        })
    }

    function stopScan() {
        if (!scanning) return
        // Stop controller discovery; also stop the dedicated scan process if still running
        runBtctl(["scan", "off"], function () { scanning = false; refreshDevices() })
        if (scanProcess.running) {
            // Attempt to stop the process; if the API ignores this, it'll end on its timeout
            scanProcess.running = false
        }
        scanTimer.stop()
    }

    function connectDevice(mac) {
        runBtctl(["connect", mac], function () { refreshDeviceInfo(mac) })
    }

    function disconnectDevice(mac) {
        runBtctl(["disconnect", mac], function () { refreshDeviceInfo(mac) })
    }

    function pairDevice(mac) {
        // Prepare adapter & agent, pair, trust and connect
        ensureAdapterReady(function () {
            runSequence([
                ["pair", mac],
                ["trust", mac],
                ["connect", mac]
            ], function () { refreshDeviceInfo(mac) })
        })
    }

    function unpairDevice(mac) {
        // 'remove' will unpair device and forget it
        runBtctl(["remove", mac], function () {
            let idx = findIndexByMac(mac)
            if (idx !== -1) devicesModel.remove(idx)
            if (!scanning) refreshDevices()
        })
    }

    function toggleTrust(mac, shouldTrust) {
        runBtctl([shouldTrust ? "trust" : "untrust", mac], function () { refreshDeviceInfo(mac) })
    }

    Timer {
        id: scanTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (scanRemaining > 0) {
                scanRemaining--
                // Poll every tick but guard with scanPollBusy to avoid queue flooding
                pollDevicesRebuild()
                if (scanRemaining === 0) stopScan()
            }
        }
    }

    Component.onCompleted: {
        if (!initialized) {
            initialized = true
            refreshDevices()
        }
    }

    // -----------------------
    // UI
    // -----------------------
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: scanning ? `Bluetooth — Scanning (${scanRemaining}s)` : "Bluetooth Manager"
                color: ColorLoader.getColor("fg")
                font.bold: true
                Layout.fillWidth: true
            }

            Button {
                text: scanning ? "Stop" : "Scan"
                onClicked: scanning ? stopScan() : startScan()

                property bool hover: false
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    // Do not consume clicks; only track hover
                    acceptedButtons: Qt.NoButton
                    onEntered: parent.hover = true
                    onExited: parent.hover = false
                }
                padding: 8
                palette.buttonText: hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                font.pixelSize: 12
                font.family: "Rubik"
                font.weight: Font.Medium
                background: Rectangle {
                    radius: 5
                    color: parent.hover ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                    border.color: ColorLoader.getColor("fg")
                    border.width: 1
                }

            }

            Button {
                text: "Refresh"
                onClicked: refreshDevices()
                property bool hover: false
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    // Do not consume clicks; only track hover
                    acceptedButtons: Qt.NoButton
                    onEntered: parent.hover = true
                    onExited: parent.hover = false
                }
                padding: 8
                palette.buttonText: hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                font.pixelSize: 12
                font.family: "Rubik"
                font.weight: Font.Medium
                background: Rectangle {
                    radius: 5
                    color: parent.hover ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                    border.color: ColorLoader.getColor("fg")
                    border.width: 1
                }
            }
        }

        Rectangle { height: 1; Layout.fillWidth: true; color: ColorLoader.getColor("fg") }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: list
                model: devicesModel
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    width: list.width
                    height: 90
                    color: "transparent"
                    border.width: 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: `${name}`
                                color: ColorLoader.getColor("fg")
                                font.pointSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Label {
                                text: `${mac}  ${paired ? "• Paired" : ""}  ${connected ? "• Connected" : ""}  ${trusted ? "• Trusted" : ""} ${rssi ? `• RSSI ${rssi}` : ""}`
                                color: ColorLoader.getColor("fg")
                                opacity: 0.8
                                font.pointSize: 9
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 6
                            Button {
                                text: connected ? "Disconnect" : "Connect"
                                onClicked: connected ? disconnectDevice(mac) : connectDevice(mac)
                                property bool hover: false
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    // Do not consume clicks; only track hover
                                    acceptedButtons: Qt.NoButton
                                    onEntered: parent.hover = true
                                    onExited: parent.hover = false
                                }
                                padding: 8
                                palette.buttonText: hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                                font.pixelSize: 12
                                font.family: "Rubik"
                                font.weight: Font.Medium
                                background: Rectangle {
                                    radius: 5
                                    color: parent.hover ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                                    border.color: ColorLoader.getColor("fg")
                                    border.width: 1
                                }
                            }
                            Button {
                                text: paired ? "Unpair" : "Pair"
                                onClicked: paired ? unpairDevice(mac) : pairDevice(mac)
                                property bool hover: false
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    // Do not consume clicks; only track hover
                                    acceptedButtons: Qt.NoButton
                                    onEntered: parent.hover = true
                                    onExited: parent.hover = false
                                }
                                padding: 8
                                palette.buttonText: hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                                font.pixelSize: 12
                                font.family: "Rubik"
                                font.weight: Font.Medium
                                background: Rectangle {
                                    radius: 5
                                    color: parent.hover ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                                    border.color: ColorLoader.getColor("fg")
                                    border.width: 1
                                }
                            }
                            Button {
                                text: trusted ? "Untrust" : "Trust"
                                onClicked: toggleTrust(mac, !trusted)
                                property bool hover: false
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    // Do not consume clicks; only track hover
                                    acceptedButtons: Qt.NoButton
                                    onEntered: parent.hover = true
                                    onExited: parent.hover = false
                                }
                                padding: 8
                                palette.buttonText: hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                                font.pixelSize: 12
                                font.family: "Rubik"
                                font.weight: Font.Medium
                                background: Rectangle {
                                    radius: 5
                                    color: parent.hover ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                                    border.color: ColorLoader.getColor("fg")
                                    border.width: 1
                                }

                            }
                            Button {
                                text: "Info"
                                onClicked: refreshDeviceInfo(mac)
                                property bool hover: false
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    // Do not consume clicks; only track hover
                                    acceptedButtons: Qt.NoButton
                                    onEntered: parent.hover = true
                                    onExited: parent.hover = false
                                }
                                padding: 8
                                palette.buttonText: hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg")
                                font.pixelSize: 12
                                font.family: "Rubik"
                                font.weight: Font.Medium
                                background: Rectangle {
                                    radius: 5
                                    color: parent.hover ? ColorLoader.getColor("fg") : ColorLoader.getColor("bg")
                                    border.color: ColorLoader.getColor("fg")
                                    border.width: 1
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: lastError.length > 0
            text: lastError
            color: "#ff6666"
            font.pointSize: 9
            wrapMode: Text.WrapAnywhere
            Layout.fillWidth: true
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: bluetoothWidget.visible = false
    }
}