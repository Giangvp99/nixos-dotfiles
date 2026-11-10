import QtQuick
import Quickshell.Services.Notifications
import "../config" as Config

QtObject {
    id: root
    required property var notification
    property bool presented: false
    property bool paused: false
    property bool suppressed: false
    readonly property int timeoutMs: !notification ? 0
        : (notification.expireTimeout < 0
            ? (notification.urgency === NotificationUrgency.Critical ? 0 : Config.Config.notificationDefaultTimeout)
            : Math.max(0, Math.min(2147483647, Math.round(notification.expireTimeout))))
    signal finished()
    signal updated()

    // Quickshell 0.3.1 exposes the wire timeout in ms despite its docs saying seconds.
    function resetTimeout() {
        if (notification && (presented || suppressed) && !paused && timeoutMs > 0) expiry.restart()
        else expiry.stop()
    }
    function reportUpdate() { resetTimeout(); updated() }
    onSuppressedChanged: resetTimeout()
    onPresentedChanged: resetTimeout()
    onPausedChanged: resetTimeout()
    onTimeoutMsChanged: resetTimeout()
    property Timer expiry: Timer {
        interval: Math.max(1, root.timeoutMs)
        repeat: false
        onTriggered: if (root.notification) root.notification.expire()
    }
    property Connections events: Connections {
        target: root.notification
        function onClosed() { root.expiry.stop(); root.finished() }
        function onSummaryChanged() { Qt.callLater(root.reportUpdate) }
        function onBodyChanged() { Qt.callLater(root.reportUpdate) }
        function onExpireTimeoutChanged() { Qt.callLater(root.reportUpdate) }
        function onUrgencyChanged() { Qt.callLater(root.reportUpdate) }
        function onAppNameChanged() { Qt.callLater(root.reportUpdate) }
        function onAppIconChanged() { Qt.callLater(root.reportUpdate) }
        function onHintsChanged() { Qt.callLater(root.reportUpdate) }
        function onActionsChanged() { Qt.callLater(root.reportUpdate) }
    }
}
