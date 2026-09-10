import QtQuick
import QtQuick.Layouts

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.IconButton {
    id: root

    readonly property var workspace:
        Services.HyprlandService.focusedWorkspace

    visible:
        workspace !== null

    implicitWidth:
        Config.Config.workspaceSize

    implicitHeight:
        Config.Config.workspaceSize

    active: true

    icon: {
        if (!workspace)
            return ""

        switch (workspace.id) {
        case 1:
            return ""

        case 2:
            return ""

        case 3:
            return ""

        case 4:
            return ""

        default:
            return workspace.id.toString()
        }
    }
}
