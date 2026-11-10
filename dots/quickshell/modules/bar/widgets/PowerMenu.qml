import QtQuick

import "../../../components" as Components
import "../popups" as Popups

Components.IconButton {
    id: root

    icon: "󰐥"
    text: ""
    Accessible.name: "Session"

    active: popup.visible

    onClicked: popup.toggle()

    Popups.PowerPopup {
        id: popup

        anchorItem:
            root
    }
}
