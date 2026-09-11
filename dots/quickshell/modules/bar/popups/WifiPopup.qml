import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

PopupWindow {
    id: root

    property Item anchorItem

    readonly property int popupWidth: 320
    readonly property int headerHeight: 44
    readonly property int networkRowHeight: 44
    readonly property int maxVisibleNetworks: 7
    readonly property int popupPadding: 12

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

    width:
        popupWidth

    height:
        headerHeight
        + listHeight
        + popupPadding * 2
        + 1

    visible: false
    grabFocus: true

    color:
        "transparent"

    anchor {
        item:
            root.anchorItem

        edges:
            Edges.Bottom
            | Edges.Right

        gravity:
            Edges.Bottom
            | Edges.Left

        margins.bottom: 8

        adjustment:
            PopupAdjustment.Slide
            | PopupAdjustment.Flip
    }

    onVisibleChanged: {
        if (visible)
            Services.NetworkService.startScanning()
        else
            Services.NetworkService.stopScanning()
    }

    Rectangle {
        anchors.fill: parent

        color:
            Config.Theme.background

        radius:
            Config.Theme.radiusMedium

        border.width: 1
        border.color:
            Config.Theme.surface

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

                        font.bold: true

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

                height: 1

                color:
                    Config.Theme.surface
            }

            /*
             * Không có Wi-Fi
             */
            Item {
                visible:
                    !Services.NetworkService.available
                    || !Services.NetworkService.enabled

                width:
                    parent.width

                height: 60

                Components.StyledText {
                    anchors.centerIn: parent

                    text:
                        !Services.NetworkService.available
                        ? "No Wi-Fi adapter"
                        : "Wi-Fi is disabled"

                    color:
                        Config.Theme.subtext
                }
            }

            /*
             * Danh sách mạng Wi-Fi
             */
            ListView {
                id: networkList

                visible:
                    Services.NetworkService.available
                    && Services.NetworkService.enabled

                width:
                    parent.width

                height:
                    root.listHeight

                clip: true
                spacing: 0

                boundsBehavior:
                    Flickable.StopAtBounds

                model:
                    Services.NetworkService.networks

                delegate: Rectangle {
                    id: networkItem

                    required property var modelData

                    readonly property var network:
                        modelData

                    width:
                        ListView.view.width

                    height:
                        root.networkRowHeight

                    radius:
                        Config.Theme.radiusSmall

                    color: {
                        if (
                            network
                            && network.connected
                        ) {
                            return Config.Theme.surface
                        }

                        if (networkMouse.containsMouse)
                            return Config.Theme.surfaceHover

                        return "transparent"
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }

                        spacing: 10

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

                            font.pixelSize:
                                Config.Theme.fontLarge
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

                    MouseArea {
                        id: networkMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape:
                            Qt.PointingHandCursor

                        enabled:
                            network
                            && !network.connected
                            && !network.stateChanging

                        onClicked: {
                            Services.NetworkService
                                .connectNetwork(network)
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration:
                                Config.Animations.fast
                        }
                    }
                }

                ScrollBar.vertical:
                    ScrollBar {
                        policy:
                            root.networkCount
                                > root.maxVisibleNetworks
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
