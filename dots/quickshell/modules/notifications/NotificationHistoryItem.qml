import QtQuick
import "../../config" as Config
import "../../services" as Services

ToastCard {
    id: root
    required property var entry
    objectName: "notificationHistory_" + entry.id
    readonly property var activeNotification: Services.NotificationState.liveNotification(entry.id)
    record: ({notification: {
        appName: entry.appName, appIcon: entry.appIcon, summary: entry.summary,
        body: entry.body + (entry.bodyTruncated ? "\n…" : ""), urgency: entry.urgency,
        actions: activeNotification ? activeNotification.actions.map(action => ({identifier: action.identifier, text: action.text})) : []
    }})
    metadata: Qt.formatDateTime(new Date(entry.receivedAt), "HH:mm") + (activeNotification ? "" : " · Archived")
    dismissLabel: "Remove notification"
    unread: entry.unread
    activeFocusOnTab: true
    Accessible.name: entry.appName + ": " + entry.summary
    border.color: activeFocus || unread ? Config.Theme.primary
        : (entry.urgency === 2 ? Config.Theme.urgent : Config.Theme.border)
    border.width: activeFocus ? Config.Theme.focusBorderWidth + 1 : Config.Theme.focusBorderWidth
    onDismissRequested: Services.NotificationState.removeHistory(entry.id)
    onActionRequested: identifier => Services.NotificationState.invokeHistory(entry.id, identifier)
    Keys.onTabPressed: event => {
        if (focusController) focusController.cycleFocus(1)
        else event.accepted = false
    }
    Keys.onBacktabPressed: event => {
        if (focusController) focusController.cycleFocus(-1)
        else event.accepted = false
    }
    Keys.onEnterPressed: Services.NotificationState.invokeHistory(entry.id, "default")
    Keys.onDeletePressed: Services.NotificationState.removeHistory(entry.id)
    Keys.onReturnPressed: Services.NotificationState.invokeHistory(entry.id, "default")
    Keys.onSpacePressed: Services.NotificationState.invokeHistory(entry.id, "default")
}
