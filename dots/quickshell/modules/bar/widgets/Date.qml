import QtQuick
import Quickshell

import "../../../components" as Components
import "../popups" as Popups

Components.IconButton {
    id: root

    icon: ""

    text:
        Qt.formatDateTime(
            clock.date,
            "ddd dd-MM"
        )

    active: popup.visible

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onClicked: popup.toggle()

    Popups.CalendarPopup {
        id: popup

        anchorItem:
            root
    }
}
