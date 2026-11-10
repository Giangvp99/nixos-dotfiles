pragma Singleton
import QtQuick
import "../config" as Config

// Plain snapshots and UI state only. Referencing this does not start a server.
QtObject {
    id: root
    property var memory: null
    property var service: null
    property bool centerOpen: false
    property var center: null
    readonly property bool available: service !== null
    readonly property bool dnd: memory ? memory.dnd : false
    readonly property var history: memory ? JSON.parse(memory.historyJson) : []
    readonly property int unreadCount: history.filter(entry => entry.unread).length

    function attachMemory(value) {
        memory = value
        // Native records will be rebound by keepOnReload after memory restoration.
        save(history.map(entry => Object.assign({}, entry, {live: false})))
    }
    function save(entries) {
        if (!memory) return
        const limit = Math.max(1, Config.Config.notificationHistoryLimit)
        memory.historyJson = JSON.stringify(entries.slice(0, limit))
        if (service) entries.slice(limit).filter(entry => entry.live).forEach(entry => service.expireId(entry.id))
    }
    function entryFor(id) { return history.find(entry => entry.id === id) || null }
    function snapshot(notification, suppressed, arrival) {
        const previous = entryFor(notification.id)
        if (notification.transient) {
            if (previous) save(history.filter(entry => entry.id !== notification.id))
            return
        }
        const restored = notification.lastGeneration && !arrival
        const entry = {
            id: notification.id,
            appName: (notification.appName || "Notification").slice(0, 256),
            appIcon: notification.appIcon || "",
            summary: notification.summary.slice(0, 1024),
            body: notification.body.slice(0, Config.Config.notificationHistoryBodyLimit),
            bodyTruncated: notification.body.length > Config.Config.notificationHistoryBodyLimit,
            urgency: notification.urgency,
            receivedAt: restored && previous ? previous.receivedAt : Date.now(),
            unread: centerOpen ? false : (restored ? Boolean(previous && previous.unread) : true),
            live: true,
            toastSuppressed: suppressed
        }
        const entries = history.slice()
        const index = entries.findIndex(item => item.id === entry.id)
        if (restored) {
            if (index >= 0) entries[index] = entry
            else entries.push(entry)
            save(entries)
        } else save([entry].concat(entries.filter(item => item.id !== entry.id)))
    }
    function closed(id) {
        save(history.map(entry => entry.id === id ? Object.assign({}, entry, {live: false}) : entry))
    }
    function rememberSuppressed(id) {
        save(history.map(entry => entry.id === id ? Object.assign({}, entry, {toastSuppressed: true}) : entry))
    }
    function markAllRead() {
        if (unreadCount) save(history.map(entry => Object.assign({}, entry, {unread: false})))
    }
    function setCenterOpen(value) {
        centerOpen = value
        if (value) {
            markAllRead()
            if (service) service.suppressToasts(false)
        }
    }
    function toggleDnd() { if (memory) memory.dnd = !memory.dnd }
    onDndChanged: if (dnd && service) service.suppressToasts(true)
    function liveNotification(id) {
        if (!service) return null
        const record = service.records.find(record => record.notification && record.notification.id === id)
        return record && record.notification.tracked ? record.notification : null
    }
    function invokeHistory(id, identifier) {
        if (!service || !liveNotification(id)) return false
        return service.invokeId(id, identifier)
    }
    function removeHistory(id) {
        if (service) service.dismissId(id)
        save(history.filter(entry => entry.id !== id))
    }
    function clearHistory() {
        const ids = history.map(entry => entry.id)
        if (service) ids.forEach(id => service.dismissId(id))
        save([])
    }
}
