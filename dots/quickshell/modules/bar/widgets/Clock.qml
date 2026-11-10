import QtQuick
import Quickshell
import "../../../config" as Config
import "../../../components" as Components

Components.StatusText {
    text: Qt.formatDateTime(clock.date, Config.Config.clockFormat)
    textWeight: Config.Theme.emphasisFontWeight
    SystemClock { id: clock; precision: SystemClock.Minutes }
}
