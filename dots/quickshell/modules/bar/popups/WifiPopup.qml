import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

BarPopup {
    id: root

    readonly property string scanOwner: "wifi-popup:" + root.openedScreenName
    readonly property int popupWidth: 320
    readonly property int headerHeight: Config.Theme.popupHeaderHeight
    readonly property int networkRowHeight: Config.Theme.popupActionHeight
    readonly property int maxVisibleNetworks: 7
    readonly property int popupPadding: Config.Theme.popupPadding

    /*
     * Quickshell ObjectModel không có .count.
     * Dùng .values.length.
     */
    readonly property int networkCount: {
        const model =
            Services.NetworkService.networks

        if (!model || !model.values)
            return 0

        return model.values.length
    }

    readonly property int visibleNetworkCount:
        Math.min(
            networkCount,
            maxVisibleNetworks
        )

    readonly property int listHeight:
        visibleNetworkCount
        * networkRowHeight

    preferredWidth:
        popupWidth

    preferredHeight:
        headerHeight
        + listHeight
        + popupPadding * 2
        + 1
        + ((!Services.NetworkService.available || !Services.NetworkService.enabled || networkCount === 0) ? 60 : 0)

    initialFocusItem: networkList.visible && networkCount > 0 ? networkList : popupSurface
    function moveNetworkFocus(delta) {
        if (!networkList.count) return
        const networks = Services.NetworkService.networks.values
        let next = networkList.currentIndex
        let found = false
        for (let i = 0; i < networkList.count; ++i) {
            next = (next + delta + networkList.count) % networkList.count
            if (networks[next] && !networks[next].stateChanging && (networks[next].connected || Services.NetworkService.canConnect(networks[next]))) { found = true; break }
        }
        if (!found) return
        networkList.currentIndex = next
        networkList.positionViewAtIndex(networkList.currentIndex, ListView.Contain)
        Qt.callLater(function() {
            if (root.visible && networkList.currentItem && networkList.currentItem.enabled) networkList.currentItem.forceActiveFocus()
        })
    }
    function cycleFocus(delta) { moveNetworkFocus(delta) }

    Connections {
        target: root
        function onVisibleChanged() {
            if (root.visible) {
                networkList.currentIndex = 0
                Services.NetworkService.startScanning(root.scanOwner)
            } else Services.NetworkService.stopScanning(root.scanOwner)
        }
    }
    Component.onDestruction: Services.NetworkService.stopScanning(root.scanOwner)

    Components.Surface {
        id: popupSurface
        panel: true
        focus: true
        Keys.onDownPressed: root.moveNetworkFocus(1)
        Keys.onUpPressed: root.moveNetworkFocus(-1)
        Keys.onTabPressed: root.moveNetworkFocus(1)
        Keys.onBacktabPressed: root.moveNetworkFocus(-1)
        Keys.onEscapePressed: root.close(true)
        anchors.fill: parent

        Column {
            anchors {
                fill: parent
                margins: root.popupPadding
            }

            spacing: 0

            /*
             * Header
             */
            Item {
                width:
                    parent.width

                height:
                    root.headerHeight

                RowLayout {
                    anchors.fill: parent

                    Components.StyledText {
                        text:
                            "Wi-Fi"

                        font.weight: Config.Theme.emphasisFontWeight

                        font.pixelSize:
                            Config.Theme.fontLarge
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Components.StyledText {
                        Layout.maximumWidth: 190

                        text: {
                            if (!Services.NetworkService.available)
                                return "No adapter"

                            if (!Services.NetworkService.enabled)
                                return "Off"

                            if (!Services.NetworkService.connected)
                                return "Disconnected"

                            return Services.NetworkService.networkName
                        }

                        color:
                            Config.Theme.subtext

                        elide:
                            Text.ElideRight
                    }
                }
            }

            /*
             * Divider
             */
            Rectangle {
                width:
                    parent.width

                height: Config.Theme.separatorWidth

                color:
                    Config.Theme.border
            }

            /*
             * Không có Wi-Fi
             */
            Item {
                visible:
                    !Services.NetworkService.available
                    || !Services.NetworkService.enabled
                    || root.networkCount === 0

                width:
                    parent.width

                height: 60

                Components.StyledText {
                    anchors.centerIn: parent

                    text:
                        !Services.NetworkService.available
                        ? "No Wi-Fi adapter"
                        : (!Services.NetworkService.enabled ? "Wi-Fi is disabled" : "No networks found")

                    color:
                        Config.Theme.subtext
                }
            }

            /*
             * Danh sách mạng Wi-Fi
             */
            ListView {
                id: networkList
                keyNavigationEnabled: false

                visible:
                    Services.NetworkService.available
                    && Services.NetworkService.enabled

                width:
                    parent.width

                height: Math.max(0, Math.min(root.listHeight, root.height - root.headerHeight - root.popupPadding * 2 - Config.Theme.separatorWidth))
                Keys.onReturnPressed: if (currentItem && currentItem.enabled) currentItem.clicked()
                Keys.onEnterPressed: if (currentItem && currentItem.enabled) currentItem.clicked()

                clip: true
                spacing: 0

                boundsBehavior:
                    Flickable.StopAtBounds

                model:
                    Services.NetworkService.networks

                delegate: Components.IconButton {
                    id: networkItem
                    focusController: root

                    required property var modelData
                    required property int index
                    Accessible.name: network ? network.name : ""
                    onActiveFocusChanged: if (activeFocus) networkList.currentIndex = index
                    onClicked: {
                        if (network && !network.connected && !network.stateChanging)
                            Services.NetworkService.connectNetwork(network)
                    }

                    readonly property var network:
                        modelData

                    width:
                        ListView.view.width

                    height:
                        root.networkRowHeight

                    enabled: network && !network.stateChanging && (network.connected || Services.NetworkService.canConnect(network))
                    background: network && network.connected ? Config.Theme.surface : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Config.Theme.controlPadding
                            rightMargin: Config.Theme.controlPadding
                        }

                        spacing: Config.Theme.controlSpacing

                        /*
                         * Signal icon
                         */
                        Components.StyledText {
                            text:
                                root.signalIcon(
                                    network
                                    ? network.signalStrength
                                    : 0
                                )

                            color:
                                network
                                && network.connected
                                ? Config.Theme.primary
                                : Config.Theme.text

                            font.family: Config.Theme.iconFontFamily
                            font.pixelSize: Config.Theme.controlIconSize
                        }

                        /*
                         * SSID
                         */
                        Components.StyledText {
                            Layout.fillWidth: true

                            text:
                                network
                                ? network.name
                                : ""

                            color:
                                network
                                && network.connected
                                ? Config.Theme.primary
                                : Config.Theme.text

                            textFormat: Text.PlainText
                            elide:
                                Text.ElideRight
                        }

                        /*
                         * State / signal %
                         */
                        Components.StyledText {
                            text: {
                                if (!network)
                                    return ""

                                if (network.connected)
                                    return "Connected"

                                if (network.stateChanging)
                                    return "Connecting…"

                                if (!network.known && !Services.NetworkService.canConnect(network))
                                    return "Use Settings"

                                return Math.round(
                                    network.signalStrength * 100
                                ) + "%"
                            }

                            color:
                                network
                                && network.connected
                                ? Config.Theme.primary
                                : Config.Theme.subtext

                            font.pixelSize:
                                Config.Theme.fontSmall
                        }
                    }

                }

                ScrollBar.vertical:
                    Components.StyledScrollBar {
                        policy:
                            networkList.contentHeight > networkList.height
                            ? ScrollBar.AsNeeded
                            : ScrollBar.AlwaysOff
                    }
            }
        }
    }

    function signalIcon(strength) {
        if (strength >= 0.75)
            return "󰤨"

        if (strength >= 0.50)
            return "󰤥"

        if (strength >= 0.25)
            return "󰤢"

        return "󰤟"
    }
}
