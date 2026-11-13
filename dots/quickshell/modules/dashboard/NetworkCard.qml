pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

DashboardCard {
    id: root
    objectName: "dashboardNetworkCard"
    title: "Network"
    property var networkService: Services.NetworkService
    property var focusController: null
    property bool settingsAvailable: false
    property bool compact: false
    contentPadding: compact ? Config.Theme.spaceLarge : Config.Theme.panelPadding
    property bool expanded: false
    property bool networkFocus: false
    readonly property bool scanActive: visible && expanded && networkService.available && networkService.enabled
    readonly property var networks: networkService.networks.values
    signal settingsRequested()
    signal focusRequested(var item)

    function focusTargets() {
        let targets = [wifiToggle, settingsButton, details]
        if (listLoader.item) targets = targets.concat(listLoader.item.focusTargets())
        return targets.filter(item => item && item.visible && item.enabled)
    }
    function cycleFocus(delta) {
        if (focusController) { focusController.cycleFocus(delta); return }
        const targets = focusTargets()
        if (!targets.length) return
        const current = targets.findIndex(item => item.activeFocus)
        targets[(current + delta + targets.length) % targets.length].forceActiveFocus()
    }
    function recoverFocus() {
        networkFocus = false
        if (details.enabled) details.forceActiveFocus()
        else if (settingsButton.enabled) settingsButton.forceActiveFocus()
        else if (focusController) focusController.cycleFocus(1)
    }
    Component.onDestruction: networkService.stopScanning("dashboard-network")
    onNetworksChanged: Qt.callLater(function() {
        if (root.networkFocus && !root.focusTargets().some(item => item.activeFocus)) root.recoverFocus()
    })
    onScanActiveChanged: {
        if (scanActive) networkService.startScanning("dashboard-network")
        else networkService.stopScanning("dashboard-network")
        if (!scanActive && networkFocus) Qt.callLater(root.recoverFocus)
    }
    Keys.onEscapePressed: event => {
        if (expanded) {
            expanded = false
            networkFocus = false
            Qt.callLater(root.recoverFocus)
        } else event.accepted = false
    }
    component NetworkButton: Components.IconButton {
        focusController: root
        border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
        onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
    }
    RowLayout {
        visible: !root.compact || !root.expanded
        Layout.fillWidth: true
        Components.StyledText {
            text: root.networkService.connectionIcon
            font.family: Config.Theme.iconFontFamily
            font.pixelSize: Config.Theme.launcherIconSize
            color: root.networkService.linkConnected ? Config.Theme.primary : Config.Theme.subtext
        }
        ColumnLayout {
            Layout.fillWidth: true
            Components.StyledText {
                Layout.fillWidth: true
                text: root.networkService.connectionLabel
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: root.networkService.connectivityText
                textFormat: Text.PlainText
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
                wrapMode: Text.Wrap
            }
        }
    }
    RowLayout {
        visible: !root.compact || !root.expanded
        Layout.fillWidth: true
        spacing: Config.Theme.spaceMedium
        Components.QuickToggle {
            id: wifiToggle
            objectName: "dashboardWifi"
            Layout.fillWidth: true
            label: "Wi-Fi"
            symbol: "󰤨"
            stateText: !root.networkService.available ? "No adapter"
                : (!root.networkService.hardwareEnabled ? "Hardware blocked" : (active ? "On" : "Off"))
            active: root.networkService.available && root.networkService.enabled
            enabled: root.networkService.available && root.networkService.hardwareEnabled
            focusController: root
            onClicked: root.networkService.setWifiEnabled(!root.networkService.enabled)
            onActiveFocusChanged: if (activeFocus) { root.networkFocus=false; root.focusRequested(this) }
        }
        NetworkButton {
            id: settingsButton
            objectName: "dashboardNetworkSettings"
            text: "Settings"
            enabled: root.settingsAvailable
            onClicked: root.settingsRequested()
            onActiveFocusChanged: if (activeFocus) root.networkFocus=false
        }
    }
    NetworkButton {
        id: details
        objectName: "dashboardNetworks"
        Layout.fillWidth: true
        fillContentWidth: true
        text: root.expanded ? "Hide networks" : "Available networks"
        icon: root.expanded ? "󰅃" : "󰅀"
        active: root.expanded
        enabled: root.networkService.available
        onClicked: root.expanded = !root.expanded
        onActiveFocusChanged: if (activeFocus) root.networkFocus=false
    }
    Loader {
        id: listLoader
        Layout.fillWidth: true
        active: root.expanded
        visible: active
        sourceComponent: ColumnLayout {
            spacing: Config.Theme.spaceSmall
            function focusTargets() {
                let targets=[]
                for(let i=0;i<rows.count;i++) targets.push(rows.itemAt(i))
                return targets.concat(pager.focusTargets())
            }
            Components.StyledText {
                Layout.fillWidth: true
                visible: !root.networkService.available || !root.networkService.enabled || root.networks.length===0
                text: !root.networkService.available ? "Wi-Fi adapter disconnected"
                    : (!root.networkService.enabled ? "Wi-Fi is disabled" : "Scanning for networks…")
                color: Config.Theme.subtext
                wrapMode: Text.Wrap
            }
            Repeater {
                id: rows
                model: root.scanActive ? root.networks.slice(pager.start, pager.start + pager.pageSize) : []
                delegate: NetworkButton {
                    id: row
                    required property int index
                    readonly property var network: root.networks[pager.start + index]
                    Layout.fillWidth: true
                    implicitHeight: Config.Theme.popupActionHeight + Config.Theme.spaceSmall
                    objectName: "dashboardNetwork_" + (pager.start + index)
                    enabled: Boolean(network && !network.stateChanging && (network.connected || root.networkService.canConnect(network)))
                    active: Boolean(network && network.connected)
                    Accessible.name: network ? network.name + ", " + root.networkService.networkStatus(network) : ""
                    onClicked: {
                        root.networkService.connectNetwork(network)
                        Qt.callLater(root.recoverFocus)
                    }
                    onActiveFocusChanged: if(activeFocus) root.networkFocus=true
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Config.Theme.spaceSmall
                        spacing: Config.Theme.spaceTiny
                        Components.StyledText {
                            Layout.fillWidth: true
                            text: row.network ? row.network.name : ""
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: row.active ? Config.Theme.controlSelected : Config.Theme.controlForeground
                        }
                        Components.StyledText {
                            Layout.fillWidth: true
                            text: row.network ? root.networkService.networkStatus(row.network) + " · " + Math.round(row.network.signalStrength*100) + "%" : ""
                            font.pixelSize: Config.Theme.fontSmall
                            color: Config.Theme.subtext
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            ChoicePager {
                id: pager
                Layout.fillWidth: true
                count: root.scanActive ? root.networks.length : 0
                pageSize: root.compact ? 2 : Math.max(1, count)
                focusController: root
                onFocusRequested: item => root.focusRequested(item)
            }
            Components.StyledText {
                Layout.fillWidth: true
                visible: root.networkService.connectionError.length > 0
                text: root.networkService.connectionError
                textFormat: Text.PlainText
                color: Config.Theme.warning
                wrapMode: Text.Wrap
            }
        }
    }
}
