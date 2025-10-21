import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Controls

import "../utils/"

FloatingWindow {
    id: bluetoothWindow
    title: "bluetooth"
    implicitWidth: 420
    implicitHeight: 480
    visible: false

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: ColorLoader.getColor("opacity-normal") + ColorLoader.getColor("bg").substring(1)
        border.color: ColorLoader.getColor("fg")
        border.width: 1
        radius: 12
        
        Rectangle { anchors.fill: parent; anchors.margins: -2; radius: 14; color: "transparent"; border.color: ColorLoader.getColor("fg"); border.width: 1; opacity: 0.1; z: -1 }
        scale: bluetoothWindow.visible ? 1.0 : 0.95
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    component ModernButton: Button {
        property bool isPrimary: false
        property bool isDestructive: false
        property bool hover: false
        
        MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; onEntered: parent.hover = true; onExited: parent.hover = false }
        padding: 10; font.pixelSize: 12; font.family: "Rubik"; font.weight: Font.Medium
        palette.buttonText: isDestructive ? (hover ? "#ffffff" : "#ff6b6b") : isPrimary ? (hover ? ColorLoader.getColor("bg") : "#ffffff") : (hover ? ColorLoader.getColor("bg") : ColorLoader.getColor("fg"))
        
        background: Rectangle {
            radius: 8
            color: parent.isDestructive ? (parent.hover ? "#ff6b6b" : "transparent") : parent.isPrimary ? (parent.hover ? "#4dabf7" : "#339af0") : (parent.hover ? ColorLoader.getColor("fg") : "transparent")
            border.color: parent.isDestructive ? "#ff6b6b" : parent.isPrimary ? "transparent" : ColorLoader.getColor("fg")
            border.width: parent.isPrimary ? 0 : 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
    }

    property bool initialized: false
    property bool scanning: false
    property bool bluetoothPowered: true
    property bool bluetoothToggling: false
    property int scanSeconds: 10
    property int scanRemaining: 0
    property string lastError: ""
    property bool scanPollBusy: false
    property bool scanPollPending: false
    property var deviceActionsInProgress: ({})
    
    function setDeviceActionInProgress(mac, action, inProgress) {
        let key = mac + "_" + action
        if (inProgress) deviceActionsInProgress[key] = true
        else delete deviceActionsInProgress[key]
        deviceActionsInProgressChanged()
    }
    
    function isDeviceActionInProgress(mac, action) { return deviceActionsInProgress.hasOwnProperty(mac + "_" + action) }

    ListModel { id: devicesModel }

    function sanitizeName(s) {
        if (!s) return s
        let t = String(s).split("\t")[0]
            .replace(/\s*\/org\/[^\s]*\s*/g, " ")
            .replace(/\s*Media\s*\/[^\s]*\s*/gi, " ")
            .replace(/\s*Media\s+.*$/gi, "")
            .replace(/\s*\[[^\]]*\]\s*/g, " ")
            .replace(/\s*\([^)]*\)\s*$/g, "")
            .replace(/\s+(Class|Icon|Appearance|UUIDs?|RSSI|Tx\s*Power|Paired|Connected|Trusted|AddressType|ManufacturerData|Services|ServiceData|Battery|Modalias|Device|Discovering|Discoverable|Pairable|Powered|Name|Alias|Media|Player|Transport|Endpoint):.*$/i, "")
            .replace(/\s+(LE|BR\/EDR|Classic|Low\s*Energy|Audio|Mouse|Keyboard|Headset|Headphones|Speaker|Controller|Gamepad)(\s|$)/gi, " ")
            .replace(/\s+(v\d+(\.\d+)*|\d+\.\d+|Model\s+\w+|Rev\s+\w+|FW\s+\w+)(\s|$)/gi, " ")
            .replace(/\s+(device|bluetooth|wireless|corp|corporation|inc|ltd|llc|co|company)(\s|$)/gi, " ")
            .replace(/^(LE-|BT-|Bluetooth\s+|Device\s+)\s*/i, "")
            .replace(/\s+(Device|Bluetooth)$/i, "")
            .replace(/[:;]+\s*$/g, "")
            .replace(/\s+/g, " ").replace(/[-,;:\s]+$/g, "").trim()
        return (!t || /^[^a-zA-Z0-9]*$/.test(t)) ? s : t
    }

    function findIndexByMac(mac) {
        for (let i = 0; i < devicesModel.count; i++) 
            if (devicesModel.get(i).mac === mac) return i
        return -1
    }

    function upsertDevice(mac, name) {
        let idx = findIndexByMac(mac)
        if (idx === -1) devicesModel.append({mac: mac, name: name || mac, paired: false, connected: false, trusted: false, rssi: ""})
        else if (name && devicesModel.get(idx).name !== name) devicesModel.setProperty(idx, "name", name)
    }

    function updateDeviceField(mac, field, value) {
        let idx = findIndexByMac(mac)
        if (idx !== -1) devicesModel.setProperty(idx, field, value)
    }

    Process {
        id: execProcess
        property var queue: []
        property var callback: null
        property string buffer: ""
        stdout: SplitParser { onRead: (data) => execProcess.buffer += data }
        stderr: SplitParser { onRead: (data) => execProcess.buffer += data }
        onRunningChanged: {
            if (!running) {
                let out = execProcess.buffer, cb = execProcess.callback
                execProcess.buffer = ""; execProcess.callback = null
                if (cb) try { cb(out) } catch (e) { lastError = String(e) }
                maybeStartQueue()
            }
        }
    }

    Process {
        id: scanProcess
        property string sbuf: ""
        stdout: SplitParser {
            onRead: (data) => {
                scanProcess.sbuf += data
                let lines = scanProcess.sbuf.split(/\r?\n/)
                scanProcess.sbuf = lines.pop()
                for (let l of lines) parseScanStreamLine(l)
            }
        }
        stderr: SplitParser {
            onRead: (data) => {
                scanProcess.sbuf += data
                let lines = scanProcess.sbuf.split(/\r?\n/)
                scanProcess.sbuf = lines.pop()
                for (let l of lines) parseScanStreamLine(l)
            }
        }
        onRunningChanged: {
            if (!running) {
                if (scanProcess.sbuf.length > 0) { parseScanStreamLine(scanProcess.sbuf); scanProcess.sbuf = "" }
                scanning = false; scanTimer.stop(); refreshDevices()
            }
        }
    }

    function parseScanStreamLine(l) {
        if (!l || (!l.startsWith("Device ") && !l.includes(" Device "))) return
        let mName = l.match(/Device\s+([0-9A-Fa-f:]{17}).*?\bName:\s*(.+)$/)
        if (mName) { upsertDevice(mName[1], sanitizeName(mName[2]) || mName[1]); return }
        let mAlias = l.match(/Device\s+([0-9A-Fa-f:]{17}).*?\bAlias:\s*(.+)$/)
        if (mAlias) { upsertDevice(mAlias[1], sanitizeName(mAlias[2]) || mAlias[1]); return }
        let m = l.match(/Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/) || l.match(/Device\s+([0-9A-Fa-f:]{17})$/)
        if (m) {
            const mac = m[1], rest = (m[2] || "").trim()
            const looksLikeField = /^((Class|Icon|Appearance|UUIDs?|RSSI|Tx\s*Power|Paired|Connected|Trusted|AddressType|ManufacturerData|Services|ServiceData)\s*:|\(|\[)/i.test(rest)
            upsertDevice(mac, looksLikeField ? mac : (sanitizeName(rest) || mac))
            return
        }
        const parts = l.trim().split(/\s+/), idx = parts.indexOf("Device")
        if (idx !== -1 && parts.length > idx + 1) {
            const mac = parts[idx + 1], rest = l.substring(l.indexOf(mac) + mac.length + 1).trim()
            const looksLikeField = /^((Class|Icon|Appearance|UUIDs?|RSSI|Tx\s*Power|Paired|Connected|Trusted|AddressType|ManufacturerData|Services|ServiceData)\s*:|\(|\[)/i.test(rest)
            if (/[0-9A-Fa-f:]{17}/.test(mac)) upsertDevice(mac, looksLikeField ? mac : (sanitizeName(rest) || mac))
        }
    }

    function runBtctl(args, cb) { execProcess.queue.push({ args: args, cb: cb }); maybeStartQueue() }

    function maybeStartQueue() {
        if (execProcess.running || execProcess.queue.length === 0) return
        const item = execProcess.queue.shift()
        execProcess.callback = item.cb || null; execProcess.command = ["bluetoothctl"].concat(item.args)
        execProcess.buffer = ""; execProcess.running = true
    }

    function runSequence(commands, finalCb) {
        let i = 0, lastOut = ""
        function next() {
            if (i >= commands.length) { if (finalCb) finalCb(lastOut); return }
            runBtctl(commands[i++], function (out) { lastOut = out; next() })
        }
        next()
    }

    function ensureAdapterReady(cb) { runSequence([["power", "on"], ["agent", "on"], ["default-agent"], ["pairable", "on"]], cb) }

    function parseDevicesList(output) {
        output.split(/\r?\n/).forEach(l => {
            if (l.startsWith("Device ")) {
                let parts = l.split(/\s+/)
                if (parts.length >= 3) upsertDevice(parts[1], sanitizeName(l.substring(l.indexOf(parts[1]) + parts[1].length + 1).trim()))
            }
        })
    }

    function parseInfo(mac, output) {
        const matches = {
            connected: output.match(/Connected:\s*(yes|no)/i),
            paired: output.match(/Paired:\s*(yes|no)/i),
            trusted: output.match(/Trusted:\s*(yes|no)/i),
            name: output.match(/^Name:\s*(.+)$/mi),
            alias: output.match(/^Alias:\s*(.+)$/mi),
            rssi: output.match(/RSSI:\s*(-?\d+)/)
        }
        if (matches.name) updateDeviceField(mac, "name", sanitizeName(matches.name[1].trim()))
        if (matches.alias) updateDeviceField(mac, "name", sanitizeName(matches.alias[1].trim()))
        if (matches.connected) updateDeviceField(mac, "connected", matches.connected[1].toLowerCase() === "yes")
        if (matches.paired) updateDeviceField(mac, "paired", matches.paired[1].toLowerCase() === "yes")
        if (matches.trusted) updateDeviceField(mac, "trusted", matches.trusted[1].toLowerCase() === "yes")
        if (matches.rssi) updateDeviceField(mac, "rssi", matches.rssi[1])
    }

    function rebuildFromOutputs(devOut, pairedOut) {
        const map = {}
        ;[devOut, pairedOut].forEach((out, isPaired) => {
            out.split(/\r?\n/).forEach(l => {
                if (!l.startsWith("Device ")) return
                let parts = l.split(/\s+/)
                if (parts.length < 3) return
                let mac = parts[1], name = sanitizeName(l.substring(l.indexOf(mac) + mac.length + 1).trim())
                map[mac] = map[mac] || { mac: mac }
                if (isPaired) map[mac].paired = true
                if (name && !map[mac].name) map[mac].name = name
            })
        })
        devicesModel.clear()
        Object.values(map).forEach(d => devicesModel.append({mac: d.mac, name: d.name || d.mac, paired: !!d.paired, connected: false, trusted: false, rssi: ""}))
        if (!scanning) for (let i = 0; i < devicesModel.count; i++) refreshDeviceInfo(devicesModel.get(i).mac)
    }

    function refreshDevices() {
        lastError = ""
        runBtctl(["devices"], devOut => runBtctl(["paired-devices"], pairedOut => rebuildFromOutputs(devOut, pairedOut)))
    }

    function pollDevicesRebuild() {
        if (scanPollBusy) { scanPollPending = true; return }
        scanPollBusy = true
        runBtctl(["devices"], devOut => runBtctl(["paired-devices"], pairedOut => {
            rebuildFromOutputs(devOut, pairedOut); scanPollBusy = false
            if (scanPollPending) { scanPollPending = false; pollDevicesRebuild() }
        }))
    }

    function refreshDeviceInfo(mac) { runBtctl(["info", mac], out => parseInfo(mac, out)) }

    function startScan() {
        if (scanning) return
        ensureAdapterReady(() => {
            devicesModel.clear(); scanning = true; scanRemaining = scanSeconds
            scanProcess.sbuf = ""; scanProcess.command = ["bluetoothctl", "--timeout", String(scanSeconds), "scan", "on"]
            scanProcess.running = true; scanTimer.start(); pollDevicesRebuild()
        })
    }

    function stopScan() {
        if (!scanning) return
        runBtctl(["scan", "off"], () => { scanning = false; refreshDevices() })
        if (scanProcess.running) scanProcess.running = false
        scanTimer.stop()
    }

    function connectDevice(mac) {
        setDeviceActionInProgress(mac, "connect", true)
        runBtctl(["connect", mac], () => { setDeviceActionInProgress(mac, "connect", false); refreshDeviceInfo(mac) })
    }

    function disconnectDevice(mac) {
        setDeviceActionInProgress(mac, "disconnect", true)
        runBtctl(["disconnect", mac], () => { setDeviceActionInProgress(mac, "disconnect", false); refreshDeviceInfo(mac) })
    }

    function pairDevice(mac) {
        setDeviceActionInProgress(mac, "pair", true)
        ensureAdapterReady(() => runSequence([["pair", mac], ["trust", mac], ["connect", mac]], () => { 
            setDeviceActionInProgress(mac, "pair", false); refreshDeviceInfo(mac) 
        }))
    }

    function unpairDevice(mac) {
        setDeviceActionInProgress(mac, "unpair", true)
        runBtctl(["remove", mac], () => {
            setDeviceActionInProgress(mac, "unpair", false)
            let idx = findIndexByMac(mac)
            if (idx !== -1) devicesModel.remove(idx)
            if (!scanning) refreshDevices()
        })
    }

    function toggleTrust(mac, shouldTrust) {
        setDeviceActionInProgress(mac, "trust", true)
        runBtctl([shouldTrust ? "trust" : "untrust", mac], () => { setDeviceActionInProgress(mac, "trust", false); refreshDeviceInfo(mac) })
    }

    function toggleBluetooth() {
        if (bluetoothToggling) return
        bluetoothToggling = true
        runBtctl(["power", bluetoothPowered ? "off" : "on"], () => {
            bluetoothToggling = false
            if (!bluetoothPowered && scanning) stopScan()
            checkBluetoothStatusAndRefresh()
        })
    }

    function checkBluetoothStatus() {
        runBtctl(["show"], output => {
            const poweredMatch = output.match(/Powered:\s*(yes|no)/i)
            if (poweredMatch) bluetoothPowered = poweredMatch[1].toLowerCase() === "yes"
        })
    }

    function checkBluetoothStatusAndRefresh() {
        runBtctl(["show"], output => {
            const poweredMatch = output.match(/Powered:\s*(yes|no)/i)
            if (poweredMatch) bluetoothPowered = poweredMatch[1].toLowerCase() === "yes"
            if (bluetoothPowered) refreshDevices(); else devicesModel.clear()
        })
    }

    Timer {
        id: scanTimer
        interval: 1000; repeat: true; running: false
        onTriggered: {
            if (scanRemaining > 0) { scanRemaining--; pollDevicesRebuild(); if (scanRemaining === 0) stopScan() }
        }
    }

    Component.onCompleted: { if (!initialized) { initialized = true; checkBluetoothStatusAndRefresh() } }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 12

        ColumnLayout {
            Layout.fillWidth: true; spacing: 10
            
            Label { text: "Bluetooth Manager"; color: ColorLoader.getColor("fg"); font.bold: true; font.pixelSize: 16; Layout.fillWidth: true }
            
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Label {
                    text: bluetoothPowered ? (scanning ? `Scanning... (${scanRemaining}s remaining)` : `${devicesModel.count} device${devicesModel.count !== 1 ? "s" : ""} found`) : "Bluetooth is disabled"
                    color: ColorLoader.getColor("fg"); opacity: bluetoothPowered ? 0.8 : 0.6; font.pixelSize: 12; Layout.fillWidth: true
                }
                ModernButton {
                    text: bluetoothToggling ? "..." : (bluetoothPowered ? "Turn Off" : "Turn On")
                    isPrimary: !bluetoothPowered && !bluetoothToggling; isDestructive: bluetoothPowered && !bluetoothToggling
                    enabled: !bluetoothToggling; onClicked: toggleBluetooth(); opacity: enabled ? 1.0 : 0.6
                }
            }
            
            RowLayout {
                Layout.fillWidth: true; spacing: 10; visible: bluetoothPowered
                Item { Layout.fillWidth: true }
                ModernButton { text: scanning ? "Stop Scan" : "Start Scan"; isPrimary: !scanning; isDestructive: scanning; onClicked: scanning ? stopScan() : startScan(); enabled: bluetoothPowered }
                ModernButton { text: "Refresh"; font.pixelSize: 12; onClicked: refreshDevices(); enabled: !scanning && bluetoothPowered; opacity: enabled ? 1.0 : 0.5; Layout.preferredWidth: 70 }
            }
        }

        Rectangle { height: 1; Layout.fillWidth: true; color: ColorLoader.getColor("fg"); opacity: 0.2 }

        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            ListView {
                id: list
                model: devicesModel; boundsBehavior: Flickable.StopAtBounds; spacing: 8
                
                Label {
                    visible: list.count === 0; anchors.centerIn: parent
                    text: !bluetoothPowered ? "Bluetooth is disabled\nTurn on Bluetooth to see devices" : scanning ? "Scanning for devices..." : "No devices found\nTap 'Start Scan' to discover devices"
                    color: ColorLoader.getColor("fg"); opacity: 0.6; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.4
                }
                
                delegate: Rectangle {
                    width: list.width; height: deviceLayout.implicitHeight + 24; color: "transparent"
                    border.width: connected ? 1 : 0; border.color: ColorLoader.getColor("fg"); radius: 10
                    property bool hovered: false
                    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; onEntered: parent.hovered = true; onExited: parent.hovered = false }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                    Rectangle { anchors.fill: parent; radius: parent.radius; color: ColorLoader.getColor("fg"); opacity: parent.hovered ? 0.05 : 0.0; Behavior on opacity { NumberAnimation { duration: 150 } } }

                    ColumnLayout {
                        id: deviceLayout
                        anchors.fill: parent; anchors.margins: 12; spacing: 10
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Rectangle { width: 12; height: 12; radius: 6; color: connected ? "#4dabf7" : paired ? "#51cf66" : ColorLoader.getColor("fg"); opacity: connected ? 1.0 : paired ? 0.8 : 0.3 }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                Label { text: name; color: ColorLoader.getColor("fg"); font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    Label { text: mac; color: ColorLoader.getColor("fg"); opacity: 0.6; font.pixelSize: 11; font.family: "monospace" }
                                    Row {
                                        spacing: 6
                                        Rectangle { visible: connected; width: connectedLabel.width + 12; height: 20; radius: 10; color: "#4dabf7"
                                            Label { id: connectedLabel; anchors.centerIn: parent; text: "Connected"; color: "white"; font.pixelSize: 10; font.weight: Font.Medium } }
                                        Rectangle { visible: paired && !connected; width: pairedLabel.width + 12; height: 20; radius: 10; color: "#51cf66"
                                            Label { id: pairedLabel; anchors.centerIn: parent; text: "Paired"; color: "white"; font.pixelSize: 10; font.weight: Font.Medium } }
                                        Rectangle { visible: trusted; width: trustedLabel.width + 12; height: 20; radius: 10; color: ColorLoader.getColor("fg"); opacity: 0.2
                                            Label { id: trustedLabel; anchors.centerIn: parent; text: "Trusted"; color: ColorLoader.getColor("fg"); font.pixelSize: 10; font.weight: Font.Medium } }
                                    }
                                    Label { visible: rssi !== ""; text: `${rssi} dBm`; color: ColorLoader.getColor("fg"); opacity: 0.5; font.pixelSize: 10; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            ModernButton {
                                property bool loading: bluetoothWindow.isDeviceActionInProgress(mac, "connect") || bluetoothWindow.isDeviceActionInProgress(mac, "disconnect")
                                text: loading ? "..." : (connected ? "Disconnect" : "Connect")
                                isPrimary: !connected && !loading && bluetoothPowered; isDestructive: connected && !loading && bluetoothPowered
                                enabled: !loading && bluetoothPowered; onClicked: connected ? disconnectDevice(mac) : connectDevice(mac)
                                Layout.preferredWidth: 90; opacity: enabled ? 1.0 : 0.4
                            }
                            ModernButton {
                                property bool loading: bluetoothWindow.isDeviceActionInProgress(mac, "pair") || bluetoothWindow.isDeviceActionInProgress(mac, "unpair")
                                text: loading ? "..." : (paired ? "Unpair" : "Pair"); isDestructive: paired && !loading && bluetoothPowered
                                enabled: !loading && bluetoothPowered; onClicked: paired ? unpairDevice(mac) : pairDevice(mac)
                                Layout.preferredWidth: 70; opacity: enabled ? 1.0 : 0.4
                            }
                            ModernButton {
                                property bool loading: bluetoothWindow.isDeviceActionInProgress(mac, "trust")
                                text: loading ? "..." : (trusted ? "Untrust" : "Trust"); enabled: !loading && bluetoothPowered
                                onClicked: toggleTrust(mac, !trusted); Layout.preferredWidth: 70; opacity: enabled ? 1.0 : 0.4
                            }
                            Item { Layout.fillWidth: true }
                            ModernButton { text: "Refresh"; font.pixelSize: 11; enabled: bluetoothPowered; onClicked: refreshDeviceInfo(mac); Layout.preferredWidth: 60; opacity: enabled ? 1.0 : 0.4 }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: lastError.length > 0; Layout.fillWidth: true; height: errorLabel.height + 16
            color: "#ff6b6b" + "20"; border.color: "#ff6b6b"; border.width: 1; radius: 8
            Label {
                id: errorLabel; anchors.centerIn: parent; text: "⚠ " + lastError; color: "#ff6b6b"
                font.pixelSize: 12; font.weight: Font.Medium; wrapMode: Text.WrapAnywhere
                width: parent.width - 16; horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: bluetoothWidget.visible = false }
}