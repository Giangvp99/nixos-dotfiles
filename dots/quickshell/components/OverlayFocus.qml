import QtQuick

// Item is cleared by Qt if its owner disappears during a reload or handoff.
QtObject {
    id: root
    property Item origin: null
    property bool opened: false
    property bool windowVisible: false
    property bool pendingRestore: false
    function remember(item) { pendingRestore = false; origin = item || null }
    function finish(restore) {
        pendingRestore = !!restore
        if (restore) Qt.callLater(restoreOrigin)
        else origin = null
    }
    onWindowVisibleChanged: if (!windowVisible && pendingRestore) Qt.callLater(restoreOrigin)
    function restoreOrigin() {
        // A queued close must never steal focus from an overlay reopened meanwhile.
        if (opened || windowVisible || !pendingRestore) return
        pendingRestore = false
        const item = origin
        origin = null
        if (item && item.visible && item.enabled) item.forceActiveFocus()
    }
}
