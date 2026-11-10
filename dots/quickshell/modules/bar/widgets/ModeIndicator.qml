import QtQuick
import "../../../components" as Components
import "../../../services" as Services
import "../../../config" as Config

Components.StatusText {
    id: root
    readonly property var workspace: Services.HyprlandService.focusedWorkspace
    readonly property string modeId: Services.ModeService.idFromWorkspace(workspace ? workspace.name : "")
    implicitWidth: Config.Config.workspaceWidth
    visible: modeId !== ""
    icon: Services.ModeService.icon(modeId)
    Accessible.name: Services.ModeService.name(modeId)
    iconColor: Config.Theme.primary
}
