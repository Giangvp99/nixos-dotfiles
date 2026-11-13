import QtQuick
import Quickshell
import "../../../components" as Components
import "../../../services" as Services

Components.IconButton {
    id: root
    objectName: "Dashboard"
    icon: "󰕮"
    active: {
        const window = root.QsWindow.window
        return Boolean(window && Services.DashboardState.opened && Services.DashboardState.controller
            && Services.DashboardState.controller.panel.screen === window.screen)
    }
    Accessible.name: "Dashboard"
    onClicked: Services.DashboardState.toggle(root)
}
