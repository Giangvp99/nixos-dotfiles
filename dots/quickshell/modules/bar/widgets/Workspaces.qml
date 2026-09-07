import QtQuick
import QtQuick.Layouts

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

RowLayout {
    id: root

    spacing: Config.Config.workspaceSpacing

    Repeater {
        model: Services.HyprlandService.workspaces

        delegate: Components.IconButton {
            id: workspaceButton

            required property var modelData

            visible:
                modelData.id > 0

            implicitWidth:
                Config.Config.workspaceSize

            implicitHeight:
                Config.Config.workspaceSize

            active:
                modelData.focused

            icon: {
                switch (modelData.id) {
                case 1:
                    return ""

                case 2:
                    return ""

                case 3:
                    return ""

                case 4:
                    return ""

                default:
                    return modelData.id.toString()
                }
            }

            onClicked:
                Services.HyprlandService
                    .activateWorkspace(modelData)
        }
    }
}
