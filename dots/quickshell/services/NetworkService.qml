pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

QtObject {
    id: root
    property var backend: Networking
    property var scanOwners: []
    property var scanningDevice: null
    property var lastAttempt: null
    property string connectionError: ""
    readonly property bool hardwareEnabled: backend.wifiHardwareEnabled

    onWifiDeviceChanged: syncScanning()
    onEnabledChanged: syncScanning()
    onScanOwnersChanged: syncScanning()
    function syncScanning() {
        const next = scanOwners.length && enabled ? wifiDevice : null
        if (scanningDevice && scanningDevice !== next) scanningDevice.scannerEnabled = false
        scanningDevice = next
        if (scanningDevice) scanningDevice.scannerEnabled = true
    }
    property Connections attemptSignals: Connections {
        target: root.lastAttempt
        ignoreUnknownSignals: true
        function onConnectionFailed() { root.connectionError = "Connection failed. Check the saved credentials in Settings." }
        function onConnectedChanged() { if (root.lastAttempt && root.lastAttempt.connected) root.connectionError = "" }
    }

    function connectionKind(name) {
        const device=backend.devices.values.find(device => device && device.name===name)
        if (!device) return "network"
        if (device.type===DeviceType.Wired) return "lan"
        if (device.type===DeviceType.Wifi) return "wifi"
        return "network"
    }
    function iconForInterface(name) {
        const kind=connectionKind(name)
        return kind==="lan" ? "󰈀" : kind==="wifi" ? "󰤨" : "󰛳"
    }

    readonly property bool statusAvailable: backend.devices.values.length > 0
    readonly property var connectedDevice: backend.devices.values.find(device => device && device.connected) || null
    readonly property bool linkConnected: connectedDevice !== null
    readonly property string connectionLabel: {
        if (!statusAvailable) return "Network details unavailable"
        if (!connectedDevice) return "Disconnected"
        if (connectedDevice.type === DeviceType.Wired) return "Ethernet · " + connectedDevice.name
        return networkName || connectedDevice.name
    }
    readonly property string connectionIcon: connectedDevice && connectedDevice.type === DeviceType.Wired ? "󰈀" : "󰤨"
    readonly property string connectivityText: {
        if (!statusAvailable) return "No connection data from the network backend"
        if (!connectedDevice) return "No active network link"
        if (!backend.canCheckConnectivity) return "Link connected"
        switch (backend.connectivity) {
        case NetworkConnectivity.Full: return "Internet available"
        case NetworkConnectivity.Portal: return "Network sign-in required"
        case NetworkConnectivity.Limited: return "Limited connectivity"
        case NetworkConnectivity.None: return "No internet access"
        default: return "Connectivity unknown"
        }
    }

    /*
     * Adapter Wi-Fi đầu tiên trên máy.
     *
     * Máy laptop thông thường chỉ có một adapter Wi-Fi,
     * nhưng cách này vẫn không hardcode wlan0/wlp...
     */
    readonly property var wifiDevice: {
        const devices =
            backend.devices.values

        for (let i = 0; i < devices.length; ++i) {
            const device =
                devices[i]

            if (
                device
                && device.type === DeviceType.Wifi
            ) {
                return device
            }
        }

        return null
    }

    readonly property bool available:
        wifiDevice !== null

    readonly property bool enabled:
        backend.wifiEnabled
        && backend.wifiHardwareEnabled

    readonly property var networks:
        wifiDevice && wifiDevice.networks
        ? wifiDevice.networks
        : emptyNetworks

    readonly property ScriptModel emptyNetworks: ScriptModel {
        values: []
    }

    /*
     * Mạng đang kết nối.
     */
    readonly property var activeNetwork: {
        if (!wifiDevice || !wifiDevice.networks)
            return null

        const list =
            wifiDevice.networks.values

        for (let i = 0; i < list.length; ++i) {
            const network =
                list[i]

            if (
                network
                && network.connected
            ) {
                return network
            }
        }

        return null
    }

    readonly property bool connected:
        activeNetwork !== null

    readonly property string networkName:
        connected
        ? activeNetwork.name
        : ""

    readonly property real signalStrength:
        connected
        ? activeNetwork.signalStrength
        : 0.0

    // Each visible consumer owns one scan request; closing one cannot stop another.
    function startScanning(owner = "wifi-popup") {
        if (scanOwners.indexOf(owner) < 0) scanOwners = scanOwners.concat([owner])
    }
    function stopScanning(owner = "wifi-popup") {
        scanOwners = scanOwners.filter(value => value !== owner)
    }
    function canConnect(network) {
        return available && enabled && network && networks.values.indexOf(network) >= 0
            && !network.connected && !network.stateChanging
            && (network.known || network.security === WifiSecurityType.Open)
    }
    function networkStatus(network) {
        if (!network) return ""
        if (network.stateChanging) return "Connecting…"
        if (network.connected) return "Connected"
        if (!network.known && network.security !== WifiSecurityType.Open) return "Set up in Settings"
        return network.known ? "Saved" : "Open network"
    }

    /*
     * Với network đã lưu hoặc mạng không cần credential,
     * connect() là đủ.
     *
     * Password UI sẽ được thêm sau mà không phải sửa
     * kiến trúc service/widget.
     */
    function connectNetwork(network) {
        if (!canConnect(network)) return
        connectionError = ""
        lastAttempt = network
        network.connect()
    }

    function disconnect() {
        if (!activeNetwork || activeNetwork.stateChanging)
            return

        activeNetwork.disconnect()
    }

    function setWifiEnabled(value) {
        if (available && hardwareEnabled) backend.wifiEnabled = value
    }
}
