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

    /*
     * Đồng bộ kích thước / padding với Audio.
     */
    implicitHeight: 28
    horizontalPadding: 10
    spacing: 6

    /*
     * Luôn có background surface.
     */
    active: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onClicked: {
        popup.visible =
            !popup.visible
    }

    Popups.CalendarPopup {
        id: popup

        anchorItem:
            root
    }
}
