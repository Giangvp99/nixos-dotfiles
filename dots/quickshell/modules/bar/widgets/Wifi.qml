import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../popups" as Popups

Components.IconButton {
    id: root

    /*
     * Hiển thị giống StatusText:
     * [ wifi-icon  SSID ]
     */
    icon:
        wifiIcon()

    text: {
        if (!Services.NetworkService.available)
            return "No Wi-Fi"

        if (!Services.NetworkService.enabled)
            return "Wi-Fi off"

        if (!Services.NetworkService.connected)
            return "Disconnected"

        return Services.NetworkService.networkName
    }

    /*
     * Cùng chiều cao với Brightness / Audio.
     */
    implicitHeight: 28

    /*
     * Không ép width cố định.
     * Width tự theo icon + SSID giống StatusText.
     */
    horizontalPadding: 10
    spacing: 6

    /*
     * Luôn dùng surface background,
     * giống Brightness và Audio.
     */
    active: true

    onClicked: {
        popup.visible =
            !popup.visible
    }

    Popups.WifiPopup {
        id: popup

        anchorItem:
            root
    }

    function wifiIcon() {
        if (!Services.NetworkService.available)
            return "󰤭"

        if (!Services.NetworkService.enabled)
            return "󰤭"

        if (!Services.NetworkService.connected)
            return "󰤯"

        const strength =
            Services.NetworkService.signalStrength

        if (strength >= 0.75)
            return "󰤨"

        if (strength >= 0.50)
            return "󰤥"

        if (strength >= 0.25)
            return "󰤢"

        return "󰤟"
    }
}
