import QtQuick

import "../../../components" as Components
import "../../../services" as Services
import "../../../config" as Config

Components.StatusText {
    id: root

    implicitWidth: Config.Config.workspaceWidth

    readonly property var workspace:
        Services.HyprlandService.focusedWorkspace

    readonly property string workspaceName:
        workspace
        ? workspace.name
        : ""

    readonly property string modeId: {
        const match =
            workspaceName.match(
                /^mode-(.+)-(primary|secondary)$/
            )

        return match
            ? match[1]
            : ""
    }

    readonly property string modeName: {
        switch (modeId) {
        case "writing":
            return "Writing"

        case "code":
            return "Code"

        case "relax":
            return "Relax"

        default:
            return ""
        }
    }

    readonly property string modeIcon: {
        switch (modeId) {
        case "writing":
            return "󰈙"

        case "code":
            return ""

        case "relax":
            return ""

        default:
            return ""
        }
    }

    visible:
        modeId !== ""

    text:
        modeIcon
}
