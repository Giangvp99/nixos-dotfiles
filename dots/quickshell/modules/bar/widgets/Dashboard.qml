import QtQuick
import "../../../components" as Components
import "../../../services" as Services

Components.IconButton {
    id: root
    icon: "󰕮"
    active: Services.DashboardState.opened
    Accessible.name: "Dashboard"
    onClicked: Services.DashboardState.toggle(root)
}
