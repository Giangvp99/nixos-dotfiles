pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

QtObject {
    id: root

    readonly property bool statusAvailable: Networking.devices.values.length > 0
    readonly property var connectedDevice: Networking.devices.values.find(device => device && device.connected) || null
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
        if (!Networking.canCheckConnectivity) return "Link connected"
        switch (Networking.connectivity) {
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
            Networking.devices.values

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
        Networking.wifiEnabled
        && Networking.wifiHardwareEnabled

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

    /*
     * Chỉ scan khi popup đang mở.
     */
    function startScanning() {
        if (!wifiDevice)
            return

        wifiDevice.scannerEnabled = true
    }

    function stopScanning() {
        if (!wifiDevice)
            return

        wifiDevice.scannerEnabled = false
    }

    /*
     * Với network đã lưu hoặc mạng không cần credential,
     * connect() là đủ.
     *
     * Password UI sẽ được thêm sau mà không phải sửa
     * kiến trúc service/widget.
     */
    function connectNetwork(network) {
        if (!network)
            return

        if (network.connected)
            return

        network.connect()
    }

    function disconnect() {
        if (!activeNetwork)
            return

        activeNetwork.disconnect()
    }

    function setWifiEnabled(value) {
        Networking.wifiEnabled = value
    }
}
