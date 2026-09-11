import QtQuick

import "../../../components" as Components
import "../popups" as Popups

Components.IconButton {
    id: root

    /*
     * Nerd Font power icon.
     */
    icon: "󰐥"
    text: ""

    implicitWidth: 34
    implicitHeight: 28

    active: true

    onClicked: {
        popup.visible =
            !popup.visible
    }

    Popups.PowerPopup {
        id: popup

        anchorItem:
            root
    }
}
