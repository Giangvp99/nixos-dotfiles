pragma Singleton
import QtQuick
import Quickshell.Services.Notifications
import "../config" as Config

QtObject {
    id: root
    property var records: []
    readonly property var visibleRecords: NotificationState.centerOpen ? [] : records.filter(record =>
        !record.suppressed && (!NotificationState.dnd || record.notification.urgency === NotificationUrgency.Critical)
    ).slice(0, Math.max(1, Config.Config.notificationMaxVisible))
    readonly property int count: records.length
    readonly property NotificationServer server: NotificationServer {
        keepOnReload: true
        persistenceSupported: false
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: false
        inlineReplySupported: false
        onNotification: notification => root.receive(notification)
    }
    Component.onCompleted: NotificationState.service = root
    Component.onDestruction: if (NotificationState.service === root) NotificationState.service = null
    property Component recordFactory: Component { NotificationRecord {} }

    function receive(notification) {
        const previous = NotificationState.entryFor(notification.id)
        const suppressed = NotificationState.centerOpen
            || (NotificationState.dnd && notification.urgency !== NotificationUrgency.Critical)
            || (notification.lastGeneration && (!previous || previous.toastSuppressed))
        NotificationState.snapshot(notification, suppressed, !notification.lastGeneration)
        if ((suppressed && notification.transient) || (!notification.transient && !NotificationState.entryFor(notification.id))) {
            notification.expire()
            return
        }
        if (records.length >= Math.max(1, Config.Config.notificationQueueLimit)) {
            NotificationState.closed(notification.id)
            notification.expire()
            return
        }
        notification.tracked = true
        const record = recordFactory.createObject(root, {notification: notification, suppressed: suppressed})
        if (!record) { NotificationState.closed(notification.id); notification.dismiss(); return }
        record.finished.connect(function() { root.removeRecord(record) })
        record.updated.connect(function() {
            if (!record.notification) return
            if (NotificationState.centerOpen) record.suppressed = true
            else if (NotificationState.dnd) record.suppressed = record.notification.urgency !== NotificationUrgency.Critical
            NotificationState.snapshot(record.notification, record.suppressed, true)
        })
        record.presented = Qt.binding(function() { return root.visibleRecords.indexOf(record) >= 0 })
        records = records.concat([record])
    }
    function removeRecord(record) {
        if (record.notification) NotificationState.closed(record.notification.id)
        records = records.filter(candidate => candidate !== record)
        record.destroy()
    }
    function suppressToasts(ordinaryOnly) {
        records.forEach(record => {
            if (!ordinaryOnly || record.notification.urgency !== NotificationUrgency.Critical) {
                if (record.notification.transient) record.notification.expire()
                else {
                    record.suppressed = true
                    NotificationState.rememberSuppressed(record.notification.id)
                }
            }
        })
    }
    function expireId(id) {
        const record = records.find(record => record.notification && record.notification.id === id)
        if (record && record.notification.tracked) record.notification.expire()
    }
    function dismissId(id) {
        const record = records.find(record => record.notification && record.notification.id === id)
        if (record) dismiss(record)
    }
    function dismiss(record) {
        if (records.indexOf(record) >= 0 && record.notification && record.notification.tracked) record.notification.dismiss()
    }
    function invokeId(id, identifier) {
        const record = records.find(record => record.notification && record.notification.id === id)
        return record ? invoke(record, identifier) : false
    }
    function invoke(record, identifier) {
        if (records.indexOf(record) < 0 || !record.notification || !record.notification.tracked) return false
        const action = record.notification.actions.find(action => action.identifier === identifier)
        if (!action) return false
        action.invoke()
        return true
    }
}
