import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.StatusText {
    id: root

    readonly property var workspace:
        Services.HyprlandService.focusedWorkspace

    visible:
        workspace !== null

    implicitWidth: Config.Config.workspaceWidth
    
    icon:
        workspaceIcon(
            workspace
            ? workspace.id
            : 0
        )

    text: ""

    foreground:
        Config.Theme.text

    iconColor:
        Config.Theme.primary

    function workspaceIcon(id) {
        switch (id) {
        case 1:
            return ""

        case 2:
            return ""

        case 3:
            return ""

        case 4:
            return ""

        default:
            return "󰍹"
        }
    }
}
