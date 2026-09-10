import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.StyledText {
    id: root

    readonly property var activeWindow:
        Services.HyprlandService.activeToplevel

    text:
        activeWindow
        ? activeWindow.title
        : ""

    color: Config.Theme.subtext

    elide: Text.ElideRight

    maximumLineCount: 1

    width: Math.min(
        implicitWidth,
        500
    )
}
