pragma Singleton
import QtQuick

QtObject {
    id: root
    property var current: null

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
        const point = popup.anchorItem.mapFromItem(item, position.x, position.y)
        if (!popup.anchorItem.contains(point)) popup.close(false)
    }
}
