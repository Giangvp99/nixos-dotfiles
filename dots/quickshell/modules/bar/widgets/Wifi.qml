import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../popups" as Popups

Components.IconButton {
    id: root

    visible: Services.NetworkService.available
    maximumWidth: Config.Config.networkMaxWidth

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

    active: popup.visible

    onClicked: popup.toggle()

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
