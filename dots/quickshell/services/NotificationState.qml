pragma Singleton
import QtQuick
import "../config" as Config

// Plain snapshots and UI state only. Referencing this does not start a server.
QtObject {
    id: root
    property var memory: null
    property var service: null
    property string fallbackDetailsJson: "{}"
    readonly property var fullDetails: JSON.parse(memory && typeof memory.detailsJson==="string" ? memory.detailsJson : fallbackDetailsJson)
    function saveDetails(details) {
        const json=JSON.stringify(details)
        if (memory && typeof memory.detailsJson==="string") memory.detailsJson=json
        else fallbackDetailsJson=json
    }
    function detailFor(id) {
        const entry=entryFor(id)
        if (!entry) return null
        const live=liveNotification(id), full=fullDetails[String(id)]
        return Object.assign({},entry,{
            summary:live ? live.summary : full ? full.summary : entry.summary,
            body:live ? live.body : full ? full.body : entry.body,
            fullAvailable:Boolean(live || (full && full.complete!==false) || (!entry.bodyTruncated && !entry.summaryTruncated))
        })
    }
    property int dndRevision: 0
    property bool centerOpen: false
    property var center: null
    property var centers: []
    function registerCenter(value) {
        if (centers.indexOf(value)<0) centers=centers.concat([value])
        if (!center) center=value
    }
    function unregisterCenter(value) {
        centers=centers.filter(item=>item!==value)
        if (center===value) center=centers[0]||null
        setCenterOpen(centers.some(item=>item.visible))
    }
    function centerForScreen(screen) { return centers.find(item=>item.anchorScreen===screen)||null }
    readonly property bool available: service !== null
    readonly property bool dnd: memory ? memory.dnd : false
    readonly property var history: memory ? JSON.parse(memory.historyJson) : []
    readonly property int unreadCount: history.filter(entry => entry.unread).length

    function attachMemory(value) {
        memory = value
        // Migrate older snapshots without discarding any text they still contain.
        const details=Object.assign({},fullDetails)
        const entries=history.map(entry=>{
            if (!details[String(entry.id)]) details[String(entry.id)]={summary:entry.summary,body:entry.body,
                complete:!entry.bodyTruncated && !entry.summaryTruncated}
            return Object.assign({},entry,{live:false,body:entry.body.slice(0,Config.Config.notificationHistoryBodyLimit),
                bodyTruncated:Boolean(entry.bodyTruncated || entry.body.length>Config.Config.notificationHistoryBodyLimit)})
        })
        saveDetails(details)
        // Native records will be rebound by keepOnReload after memory restoration.
        save(entries)
    }
    function save(entries) {
        if (!memory) return
        const limit = Math.max(1, Config.Config.notificationHistoryLimit)
        const retained=entries.slice(0,limit), details={}
        for (const entry of retained) {
            const full=fullDetails[String(entry.id)]
            if (full) details[String(entry.id)]=full
        }
        let size=Object.values(details).reduce((sum,full)=>sum+full.summary.length+full.body.length,0)
        // Keep whole notifications; evict oldest messages instead of truncating their reader text.
        // A single oversized latest message is retained so it remains fully readable.
        while (size>Config.Config.notificationFullTextBudget && retained.length>1) {
            const removed=retained.pop(), full=details[String(removed.id)]
            if (full) size-=full.summary.length+full.body.length
            delete details[String(removed.id)]
        }
        saveDetails(details)
        memory.historyJson = JSON.stringify(retained)
        const ids=retained.map(entry=>entry.id)
        if (service) entries.filter(entry=>ids.indexOf(entry.id)<0 && entry.live).forEach(entry=>service.expireId(entry.id))
    }

    function entryFor(id) { return history.find(entry => entry.id === id) || null }
    function snapshot(notification, suppressed, arrival) {
        const previous = entryFor(notification.id)
        if (notification.transient) {
            if (previous) save(history.filter(entry => entry.id !== notification.id))
            return
        }
        const details=Object.assign({},fullDetails)
        details[String(notification.id)]={summary:notification.summary,body:notification.body,complete:true}
        saveDetails(details)
        const restored = notification.lastGeneration && !arrival
        const entry = {
            id: notification.id,
            appName: (notification.appName || "Notification").slice(0, 256),
            appIcon: notification.appIcon || "",
            summary: notification.summary.slice(0, 4096),
            summaryTruncated: notification.summary.length > 4096,
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
        if (centers.length) value=centers.some(item=>item.visible)
        centerOpen = value
        if (value) {
            markAllRead()
            if (service) service.suppressToasts(false)
        }
    }
    function toggleDnd() { if (memory) memory.dnd = !memory.dnd }
    onDndChanged: { dndRevision++; if (dnd && service) service.suppressToasts(true) }
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
