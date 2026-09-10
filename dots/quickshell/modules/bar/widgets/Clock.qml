import QtQuick
import Quickshell

import "../../../config" as Config
import "../../../components" as Components

Components.Surface {
    id: root

    implicitWidth:
        clockText.implicitWidth + 18

    implicitHeight: 28

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Components.StyledText {
        id: clockText

        anchors.centerIn: parent

        text:
            Qt.formatDateTime(
                clock.date,
                Config.Config.clockFormat
            )

        font.bold: true
    }
}
