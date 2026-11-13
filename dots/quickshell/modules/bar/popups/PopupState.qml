pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root
    property var current: null
    function refreshAnchor() { if (current) current.refreshAnchor() }

    function claim(popup) {
        const previous = current
        current = popup
        if (previous && previous !== popup)
            previous.close(false)
    }

    function release(popup) {
        if (current === popup) current = null
    }

    function dismissBarTap(item, position) {
        const popup = current
        if (!popup || !popup.anchorItem) return
        const sourceWindow = item.QsWindow.window
        if (!sourceWindow || sourceWindow.screen !== popup.anchorScreen) { popup.close(false); return }
        const point = popup.anchorItem.mapFromItem(item, position.x, position.y)
        if (!popup.anchorItem.contains(point)) popup.close(false)
    }
}
