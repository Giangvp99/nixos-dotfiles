import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.StyledText {
    id: root

    property var workspace: Services.HyprlandService.focusedWorkspace
    readonly property var activeWindow: Services.HyprlandService.activeToplevelFor(workspace)

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
