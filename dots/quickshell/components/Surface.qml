import QtQuick

import "../config" as Config

Rectangle {
    property bool panel: false
    border.width: panel ? 1 : 0
    border.color: Config.Theme.border

    color: panel ? Config.Theme.background : Config.Theme.surface
    radius: Config.Theme.radiusMedium
}
