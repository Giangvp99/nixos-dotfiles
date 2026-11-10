import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../../notifications" as NotificationsModule

Components.IconButton {
    id: root
    readonly property alias centerPopup: center
    enabled: Services.NotificationState.available
    icon: Services.NotificationState.dnd ? "󰂛" : "󰂚"
    text: Services.NotificationState.unreadCount ? (Services.NotificationState.unreadCount > 99 ? "99+" : Services.NotificationState.unreadCount.toString()) : ""
    active: center.visible
    iconColor: Services.NotificationState.dnd ? Config.Theme.warning
        : (active || Services.NotificationState.unreadCount ? Config.Theme.primary : Config.Theme.controlIcon)
    Accessible.name: enabled ? "Notifications, " + Services.NotificationState.unreadCount + " unread" : "Notifications unavailable"
    onClicked: center.toggle()
    NotificationsModule.NotificationCenter { id: center; anchorItem: root }
}
